#!/usr/bin/perl -w

use strict;
use v5.18;

# Unlike the backup-db script, this one does not have support
# for a config file because it is not expected to be run
# automatically.
# This is more of a disaster recovery tool, to restore the files
# generates by the backup-db script.

use DBI;
use Text::CSV;
use Config::Tiny;
use Getopt::Long;
use Term::ReadKey qw();
use Term::ANSIColor qw(colored);

my %defaults = (
  database  => 'postfix',
  dbhost    => 'localhost',
  dbuser    => 'root',
  basedir   => '.',
  config    => "$ENV{HOME}/.openops_email.ini",
  verbose   => 1,
);

my $config_file = $defaults{ config };
my $dbhost      = undef;
my $database    = undef;
my $dbuser      = undef;
my $dbpass      = undef;
my $basedir     = undef;
my $reset       = undef;
my $verbose     = undef;
my $help        = 0;

my %admins = ();

init();
eval {
  unless ($help) {
    my $dbh = get_dbh();
  }
} or do {
  trace( 0 => "Failed to connect to the database" );
  print STDERR "\n\n";
  $help = 1;
};

if ( $help ) {
  help();
  exit 1;
}

reset_db() if $reset;
import_data();

exit 0;


sub import_data {
  import_domains();
  import_ALL();
}

sub import_domains {
  my $fname = "$basedir/domains.csv";
  my $csv = CSV_File->load( $fname );

  my @cols = $csv->columns();
  my $sth  = make_insert_sth( 'domain', \@cols, 'domain' );

  while (my $dom = $csv->next()) {
    trace( 1 => "Importing '$dom->{domain}'" );
    my $dir = "$basedir/$dom->{domain}";
    if (-d $dir) {
      import_domain_admins( $dir, $dom->{domain} );
      import_domain_aliases( $dir, $dom->{domain} );
      import_domain_mailboxes( $dir, $dom->{domain} );
    }
    $sth->execute( @$dom{ @cols } );
  }
}

sub import_domain_mailboxes {
  my ($dir, $dom) = @_;

  my $fname = "$dir/mailbox.csv";
  return unless -f $fname;
  trace(2 => "Importing mailboxes for '$dom'");
  import_csv( $fname, 'mailbox', 'username', 3, sub {
      _check_domain( @_, 'username', $dom )
    });
}

sub import_domain_aliases {
  my ($dir, $dom) = @_;

  my $fname = "$dir/alias.csv";
  return unless -f $fname;
  trace( 2 => "Importing aliases for '$dom'");
  import_csv( $fname, 'alias', 'address', 3, sub {
      _check_domain( @_, 'address', $dom )
    });
}

sub import_domain_admins {
  my ($dir, $dom) = @_;

  my $fname = "$dir/domain_admins.csv";
  return unless -f $fname;

  trace( 2 => "Importing domain admins" );
  if ($reset) {
    import_csv( $fname, 'domain_admins', 'username', 3, sub {
        _check_domain( @_, 'username', $dom )
      });
  } else {
    trace( -1 => "TODO: import domain admins without reset - no PK");
  }
}

sub import_ALL {
  trace( 1 => "Importing Base data" );
  import_domain_admins("$basedir/ALL", 'ALL');
  import_alias_domains();
  import_admins();
}

sub import_alias_domains {
  my $fname = "$basedir/ALL/alias_domain.csv";
  return unless -f $fname;

  trace( 2 => "Importing alias domains");
  import_csv( $fname, 'alias_domain', 'alias_domain'. 3);
}

sub import_admins {
  my $fname = "$basedir/ALL/admin.csv";
  return unless -f $fname;

  trace( 2 => "Importing admin accounts");
  import_csv( $fname, 'admin', 'username', 3);
}

sub import_csv {
  my ($fname, $table, $pk, $trace_level, $check) = @_;

  return unless -f $fname;
  my $csv = CSV_File->load( $fname );
  my @cols = $csv->columns();
  if ( grep { ! /\A\w+\z/ } @cols ) {
    trace( 0 => "$fname have invalid field names");
    exit 1;
  }

  my $sth = make_insert_sth( $table, \@cols, $pk );
  while ( my $row = $csv->next() ) {
    if (!$check or $check->( $row )) {
      my $rv = $sth->execute( @$row{ @cols } );
      trace( $trace_level => $row->{$pk} );
    } else {
      trace( -$trace_level => $row->{check_error});
    }
  }
}

sub _check_domain {
  my ($row, $pk, $dom) = @_;

  return 1 if $row->{domain} eq $dom;

  $row->{check_error} = "$row->{pk} is for domain $row->{domain}";

  return 0;
}

sub make_insert_sth {
  my ($table, $cols, $pk) = @_;

  my $sql = join ", ", map { "$_ = ?" } @$cols;
  my $odku = join ", ", map { "$_ = VALUES($_)" } grep { $_ ne $pk } @$cols;

  $sql = <<EoQ;
INSERT INTO $table
  SET $sql
  ON DUPLICATE KEY UPDATE
    $odku
EoQ

  my $sth = get_dbh()->prepare( $sql );

  return $sth;
}

sub reset_db {
  trace( -1 => "Going to reset the database - confirmation needed!!");

  print STDERR <<EoW;

This is going to delete all data in the database!

All domains, all mailboxes, all aliases currently handled will be lost!

We recommend you create a backup of your settings using the backup-db script!

If you already did that or you are sure that you don't need one, please
answer the next question with 'Yes, please continue!'.

EoW

  print "Do you want to continue? ";
  my $reply = <>;
  chomp $reply;

  if ($reply eq 'Yes, please continue!') {
    _reset_db();
  } else {
    trace( 0 => 'Confirmation failed - dropping out!' );
  }
}

sub _reset_db {
  my $dbh = get_dbh();
  trace( 1 => "Deleting existing data");

  trace( 2 => "Deleting existing domains");
  $dbh->do("TRUNCATE domain");

  trace( 2 => "Deleting existing admin accounts" ); 
  $dbh->do("TRUNCATE admin");

  trace( 2 => "Deleting domain admins");
  $dbh->do("TRUNCATE domain_admins");

  trace( 2 => "Deleting all aliases");
  $dbh->do("TRUNCATE alias");

  trace( 2 => "Deleting all alias domains");
  $dbh->do("TRUNCATE alias_domain");

  trace( 2 => "Deleting all fetchmail configs" );
  $dbh->do("TRUNCATE fetchmail");

  trace( 2 => "Deleting all mailboxes" );
  $dbh->do("TRUNCATE mailbox");

  trace( 2 => "Deleting all quota and vacation settings, just in case");
  $dbh->do("TRUNCATE quota");
  $dbh->do("TRUNCATE quota2");
  $dbh->do("DELETE FROM vacation");
  $dbh->do("DELETE FROM vacation_notification");

  trace( 2 => "Reseting logs");
  $dbh->do("TRUNCATE log");
  my $user = getlogin || getpwuid($<) || 'whoknows';
  $dbh->do(<<EoQ);
INSERT INTO log
  (timestamp,username,domain,action,data)
  VALUES(
    NOW(),
    'unix:$user',
    'ALL',
    'restore-db',
    'at this moment we cleaned up the database to restore a
     previously backed up set of configurations - Cheers'
  )
EoQ

}


sub get_dbh {
  state $dbh;

  $dbh ||= DBI->connect(
                "DBI:mysql:database=$database;host=$dbhost",
                $dbuser,
                $dbpass,
                { RaiseError => 1 },
            );

  return $dbh;
}

sub trace {
  my ($level, $text) = @_;

  return if $level > $verbose;

  my $color = {
     -1 => 'red',
      0 => 'red',
      1 => 'bold blue',
      2 => 'yellow',
      3 => 'reset',
     -3 => 'yellow',
      4 => 'cyan',
    }->{ $level };
  my $prefix  = {
     -1 => '!! ',
      0 => 'ERROR: ',
      1 => '>> ',
      2 => ' -- ',
      3 => '  ++ ',
     -3 => '  ?? ',
      4 => '# ',
    }->{ $level } || '';

  print STDERR "\n" if abs($level) < 2;
  if ( -t STDERR ) {
    print STDERR colored( [$color], "$prefix$text"),"\n";
  } else {
    print STDERR "$prefix$text\n";
  }
}

sub init {

  my $askpassword = undef;

  GetOptions(
    'database=s'    => \$database,
    'hostname=s'    => \$dbhost,
    'user_db=s'     => \$dbuser,
    'password'      => \$askpassword,
    'basedir=s'     => \$basedir,
    'reset_db|reset'=> \$reset,
    'verbose|v'     => \$verbose,
    'vv'            => sub { $verbose = 2 },
    'vvv'           => sub { $verbose = 3 },
    'quiet'         => sub { $verbose = 0 },
    'help'          => \$help,
  );

  $database ||= $defaults{database};
  $dbuser   ||= $defaults{dbuser};
  $basedir  ||= $defaults{basedir};
  $dbhost   ||= $defaults{dbhost};
  $verbose  //= $defaults{verbose};

  if ( $askpassword ) {
    print "Password for '$dbuser\@$dbhost\[$database]': ";
    Term::ReadKey::ReadMode('noecho');
    $dbpass = Term::ReadKey::ReadLine(0);
    Term::ReadKey::ReadMode('normal');
    chomp($dbpass);
  } else {
    $dbpass = $ENV{DB_PFRESTORER_PWD}
      if $ENV{DB_PFRESTORER_PWD};
  }

  $basedir =~ s{/\z}{};
}

sub help {
  print STDERR <<EoH;
$0 Usage:

  --database=<...>    - name of the database to dump
          the default is '$defaults{database}'

  --hostname=<...>    - the hostname of the database to connect to
          the default if 'localhost'

  --user_db=<'''>     - the username to use to connect to the database
          the default is 'root'

  --password          - ask the user to type the password to use to connect
            to the database. the default password is ''
          - as the first version of this script was written in 2020,
            I don't expect that will ever work for anyone - specially
            together with user_db=root
          - the password can also be set using the ENV variable
            DB_PFRESTORER_PWD

  --basedir=<...>     - the base directory where the data in the database
            will be exported to.
          the default is the current directory

  --reset_db          - drop all the data that exists in the database
          the default is false

  -v|vv|vvv           - the level of verbosity you want
          the default is 1 (same as -v)

  -q                  - disable verbosity completely
  
EoH
}

package CSV_File;

use Text::CSV;

sub load {
  my ($class, $fname) = @_;

  my $self = bless {
      _fname  => $fname,
      csv     => Text::CSV->new({eol => $/ }),
    }, $class;

  open my $fh, '<', $fname or die "Can't open file '$fname'";;
  $self->{_fh} = $fh;

  $self->{csv}->header( $fh );

  return $self;
}

sub next {
  my ($self) = @_;

  return $self->{csv}->getline_hr( $self->{_fh} );
}

sub columns {
  my ($self) = @_;

  return $self->{csv}->column_names;
}
