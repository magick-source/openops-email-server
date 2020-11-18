#!/usr/bin/perl -w

use strict;
use v5.18;

# This script is the preparative part of disaster recovery
# which we never want to use, but are very happy when we
# need to do it and have the tools to make it happen.
# This script create files that allows the recovery of the
# configs at the point in time when the files were generated
#
# What is done with this files defines the options available
# when a problem happens and we need to restore the server.
#
# Some opens are:
# - backup them using some backup system
# - pushing this files to a git repo
# - zip them and send them by email [hopefully to a different server]
# - ... - just keep them save somewhere else, otherwise there is no point
#
# The idea is that you run this script to create the backup files
#   and then keep them safe, somewhere. To restore them use the restore-db.pl
#   script that.

use DBI;
use Text::CSV;
use Config::Tiny;
use Getopt::Long;
use Term::ANSIColor qw(colored);

my %defaults = (
    database  => 'postfix',
    dbhost    => 'localhost',
    dbuser    => 'root',
    basedir   => '.',
    config    => "$ENV{HOME}/.openops_email.ini",
    verbose   => 1
);

my $config_file = $defaults{ config };
my $dbhost      = undef;
my $database    = undef;
my $dbuser      = undef;
my $dbpass      = undef;
my $basedir     = undef;
my $delete_old  = undef;
my $verbose     = undef;
my $help        = 0;

my %unused_files = ();

init();
eval {
  unless ($help) {
    # Just to check
    my $dbh = get_dbh();
  }
} or do {
  trace( 0 => "Failed to connect to the database" );
  print STDERR "\n\n";
  $help = 1;
};

if ($help) {
  help();
  exit 0;
}

my $csv = Text::CSV->new({eol => $/ });

find_existing_files() if $delete_old;
dump_postfix_data();
delete_unused_files() if $delete_old;

exit 0; #just to be clear that nothing else happens



sub find_existing_files {
  my ($dir) = @_;

  trace( 1 => "Find the old files" ) unless $dir;
  
  $dir = $basedir unless $dir;

  my @files = <"$dir/*">;
  for my $fname ( @files ) {
    if (-f $fname) {
      trace( 3 => $fname );
      $unused_files{ $fname } = undef;
    } elsif (-d $fname) {
      find_existing_files( $fname );
    } else {
      warn "interesting fname: $fname";
    }
  }
}

sub delete_unused_files {
  my %dirs2check = ();

  return unless keys %unused_files;

  trace( 1 => "Removing unused files" );
  for my $fname ( sort keys %unused_files ) {
    trace( 2 => "Removing $fname");
    unlink $fname;
    (my $dir = $fname) =~ s{/[^/]+\z}[];
    $dirs2check{ $dir }++;
  }

  for my $dir (reverse sort keys %dirs2check) {
    my @files = <"$dir/*">;
    unless (@files) {
      trace( 2 => "Removing empty directory '$dir'");
      rmdir $dir;
    }
  }

}

sub dump_postfix_data {
  trace(4 => 'Starting the dump');

  my $domains = dump_domains();
  return unless $domains;
  dump_ALL();
  for my $dom (@$domains) {
    dump_domain( $dom );
  }

  return;
}

sub dump_domains {
  trace(1  => 'Dumping domains');
  
  my @domains = ();

  my ($sth, $row) = run_query(<<EoQ);
SELECT * FROM domain WHERE domain <> 'ALL'
EoQ

  unless ($sth->rows) {
    trace(0 => "No domains to dump");
    return;
  }

  open my $domfh, '>', "$basedir/domains.csv"
    or die "Error opening $basedir/domains.csv: $!";

  delete $unused_files{ "$basedir/domains.csv" };

  sth2file( $sth, $domfh, $row,
      sub {
        return if 
        push @domains, $row->{domain};
        trace( 3 => $row->{domain} );
      }
    );
  
  close $domfh;

  return \@domains;
}

sub dump_ALL {
  my $dir = $basedir.'/ALL';
  mkdir $dir unless -d $dir;

  trace( 1 => "Dumping base data" );

  dump_alias_domains($dir);
  dump_admins($dir);
  dump_domain_admins($dir, 'ALL');
}

sub dump_alias_domains {
  my ($dir) = @_;
  
  my ($sth, $row) = run_query(<<EoQ);
SELECT * FROM alias_domain
EoQ

  return unless $sth->rows;
  trace(2 => "Dumping alias domains");

  open my $aldomfh, '>', "$dir/alias_domain.csv"
    or die "Error opening $dir/alias_domain.csv: $!";

  delete $unused_files{ "$dir/alias_domain.csv" };

  sth2file( $sth, $aldomfh, $row,
      sub { trace( 3 => $row->{alias_domain} ) }
    );

  close $aldomfh;
  return;
}

sub dump_admins {
  my ($dir) = @_;

  my ($sth, $row) = run_query(<<EoQ);
SELECT * FROM admin
EoQ

  return unless $sth->rows;
  trace(2 => "Dumping admin accounts");

  open my $admfh, '>', "$dir/admin.csv"
    or die "Error opening $dir/admin.csv: $!";

  delete $unused_files{ "$dir/admin.csv" };

  sth2file( $sth, $admfh, $row,
      sub { trace( 3 => $row->{username} ) }
    );

  close $admfh;
  return;
}

sub dump_domain {
  my ($domain) = @_;

  trace( 1 => "Dumping $domain" );
  my $dir = "$basedir/$domain";
  mkdir $dir unless -d $dir;

  dump_domain_admins( $dir, $domain );
  dump_domain_aliases( $dir, $domain );
  dump_mailboxes( $dir, $domain );

  return;
}

sub dump_mailboxes {
  my ($dir, $domain) = @_;

  my ($sth, $row) = run_query(<<EoQ, $domain);
SELECT * FROM mailbox WHERE domain = ?
EoQ
  
  return unless $sth->rows;
  trace( 2 => "Dumping mailboxes for '$domain'");

  open my $mxfh, '>', "$dir/mailbox.csv"
    or die "Error opening $dir/mailbox.csv: $!";
  
  delete $unused_files{ "$dir/mailbox.csv" };
  
  sth2file( $sth, $mxfh, $row,
      sub { trace( 3 => $row->{username} ) },
    );
  close $mxfh;

  return;
}

sub dump_domain_aliases {
  my ($dir, $domain) = @_;

  my ($sth, $row) = run_query( <<EoQ, $domain);
SELECT * FROM alias WHERE domain = ?
EoQ

  return unless $sth->rows;
  trace( 2 => "Dumping alias for '$domain'" );

  open my $alfh, '>', "$dir/alias.csv"
    or die "Error opening $dir/alias.csv: $!";
  
  delete $unused_files{ "$dir/alias.csv" };
  
  sth2file( $sth, $alfh, $row,
      sub { trace( 3 => $row->{address} ) }
    );

  close $alfh;
  return;
}

sub dump_domain_admins {
  my ($dir, $domain) = @_;

  my ($sth, $row) = run_query(<<EoQ, $domain);
SELECT * FROM domain_admins WHERE domain = ?
EoQ

  return unless $sth->rows;  
  trace( 2 => "Dumping domain admin for $domain" );

  open my $domafh, '>', "$dir/domain_admins.csv"
    or die "Error opening $dir/domain_admins.csv: $!";
  
  delete $unused_files{ "$dir/domain_admins.csv" };
  
  sth2file( $sth, $domafh, $row,
      sub { trace(3 => $row->{username}) }
    );
  close $domafh;
  return;
}

sub run_query {
  my ($query, @binds) = @_;

  my $dbh = get_dbh();
  my $sth = $dbh->prepare( $query );
  $sth->execute(@binds);

  my $cols = $sth->FETCH('NAME_lc');

  my %row;
  @row{ @$cols } = ();

  $sth->bind_columns( \@row{ @$cols } );

  return ( $sth, \%row );
}

sub sth2file {
  my ($sth, $fh, $row, $log) = @_;

  my $cols = $sth->FETCH('NAME_lc');
  $csv->say( $fh, $cols );

  while ($sth->fetch()) {
    $log->() if $log;
    $csv->say($fh, [@$row{ @$cols }] );
  }

  return;
}

sub get_dbh {
  state $dbh;

  $dbh ||= DBI->connect(
                "DBI:mysql:database=$database;host=$dbhost",
                $dbuser,
                $dbpass,
                { RaiseError => 1 }
            );

  return $dbh;
}

sub trace {
  my ($level, $text) = @_;

  return if $level > $verbose;

  my $color = {
      0 => 'red',
      1 => 'bold blue',
      2 => 'yellow',
      3 => 'reset',
      4 => 'cyan',
    }->{ $level };
  my $prefix  = {
      0 => 'ERROR: ',
      1 => '>> ',
      2 => ' -- ',
      3 => '  ++ ',
      4 => '# ',
    }->{ $level };

  print STDERR "\n" if $level < 2;
  if ( -t STDERR ) {
    print STDERR colored( [$color], "$prefix$text"),"\n";
  } else {
    print STDERR "$prefix$text\n";
  }
}

sub init {

  my $askpassword = undef;
  GetOptions(
    'config_file=s' => \$config_file,
    'database=s'    => \$database,
    'hostname=s'    => \$dbhost,
    'user_db=s'     => \$dbuser,
    'password'      => \$askpassword,
    'basedir=s'     => \$basedir,
    'delete_old|del'=> \$delete_old,
    'verbose|v'     => \$verbose,
    'vv'            => sub { $verbose = 2 },
    'vvv'           => sub { $verbose = 3 },
    'quiet'         => sub { $verbose = 0 },
    'help'          => \$help,
  );

  if ( $config_file and -e $config_file ) {
    my $config = Config::Tiny->read( $config_file );

    if ( $config and $config->{_} ) {
      my $cfg = $config->{_};
      $database   ||= $cfg->{database};
      $dbhost     ||= $cfg->{hostname};
      $dbuser     ||= $cfg->{username};
      $dbpass     ||= $cfg->{password};
      $basedir    ||= $cfg->{basedir};
      $delete_old //= $cfg->{delete} // $cfg->{'delete-old'};
      $verbose    //= $cfg->{versbose};
    }
  }

  $database ||= $defaults{database};
  $dbuser   ||= $defaults{dbuser};
  $basedir  ||= $defaults{basedir};
  $dbhost   ||= $defaults{dbhost};
  $verbose  //= $defaults{verbose};

  if ( $askpassword ) {
    print "Please type the password for '$dbuser\@$dbhost\[$database]': ";
    $dbpass = <>;
    chomp($dbpass);
  }

  $basedir =~ s/^~/$ENV{HOME}/; #config needs to be expanded
  $basedir =~ s{/\z}{};
}

sub help {
  print STDERR <<EoH;
$0 Usage:

  --config_file=<...> - specific which config file to use
          the default is '$defaults{config}'

  --database=<...>    - name of the database to dump
          the default is '$defaults{database}'
          can be set with the config 'database'

  --hostname=<...>    - the hostname of the database to connect to
          the default if 'localhost'
          can be set with the config 'hostname'

  --user_db=<'''>     - the username to use to connect to the database
          the default is 'root'
          can be set with the config 'username'

  --password          - ask the user to type the password to use to connect
            to the database. the default password is ''
          - as the first version of this script was written in 2020,
            I don't expect that will ever work for anyone - specially
            together with user_db=root
          the password can be set with the config 'password'

  --basedir=<...>     - the base directory where the data in the database
            will be exported to.
          the default is the current directory
          can be set with the config 'basedir'

  --delete_old        - delete old existing files that are not needed anymore
          the default is false
          can be set with the contig 'delete' or 'delete-old'

  -v|vv|vvv           - the level of verbosity you want
          the default is 1 (same as -v)
          can be set with the config 'verbose'

  -q                  - disable verbosity completely
          in the config use 'verbose=0' to achieve the same result
  
EoH
}

