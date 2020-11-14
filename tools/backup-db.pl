#!/usr/bin/perl -w

use strict;
use v5.18;

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
);

my $config_file = $defaults{ config };
my $dbhost      = undef;
my $database    = undef;
my $dbuser      = undef;
my $dbpass      = undef;
my $basedir     = undef;
my $verbose     = 1;
my $help        = 0;


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

dump_postfix_data();

exit 0; #just to be clean that nothing else happens

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

  open my $domfh, '>', "$basedir/domains.csv";

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

  open my $aldomfh, '>', "$dir/alias_domain.csv";

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

  open my $admfh, '>', "$dir/admin.csv";

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

  my ($sth, $row) = run_query(<<EoQ);
SELECT * FROM mailbox WHERE domain = ?
EoQ
  
  return unless $sth->rows;
  trace( 2 => "Dumping mailboxes for '$domain'");

  open my $mxfh, '>', "$dir/mailbox.csv";
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

  open my $alfh, '>', "$dir/alias.csv";
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

  open my $domafh, '>', "$dir/domain_admins.csv";
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
                $dbpass
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
  GetOptions(
    'config_file=s' => \$config_file,
    'database=s'    => \$database,
    'hostname=s'    => \$dbhost,
    'user_db=s'     => \$dbuser,
    'pass_db=s'     => \$dbpass,
    'basedir=s'     => \$basedir,
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
      $database ||= $cfg->{database};
      $dbhost   ||= $cfg->{hostname};
      $dbuser   ||= $cfg->{username};
      $dbpass   ||= $cfg->{password};
      $basedir  ||= $cfg->{basedir};
    }
  }

  $database ||= $defaults{database};
  $dbuser   ||= $defaults{dbuser};
  $basedir  ||= $defaults{basedir};
  $dbhost   ||= $defaults{dbhost};
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

  --pass_db=<...>     - the password to use to connect to the database
          the default is ''
          - as the first version of this script was written in 2020,
            I don't expect that will ever work for anyone - specially
            together with user_db=root
          can be set with the config 'password'

  --basedir=<...>     - the base directory where the data in the database
            will be exported to.
          the default is the current directory
    
  -v|vv|vvv           - the level of verbosity you want
          the default is 1 (same as -v)

  -q                  - disable verbosity completely
  
EoH
}

