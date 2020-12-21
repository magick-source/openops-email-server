#!/usr/bin/perl -w

use strict;
use v5.18;

use DBI;
use Net::DNS;
use Config::Tiny;
use Getopt::Long;
use Term::ANSIColor qw(colored);

my %defaults = (
    database  => 'postfix',
    dbhost    => 'localhost',
    dbuser    => 'root',
    config    => "$ENV{HOME}/.openops_email.ini",
);

my $config_file = $defaults{ config };
my $dbhost      = undef;
my $database    = undef;
my $dbuser      = undef;
my $dbpass      = undef;
my $verbose     = undef;
my $help        = 0;

init();
eval {
  unless ($help) {
    # just to check
    my $dbh = get_dbh();
  }
} or do {
  info(ERROR => 'Failed to connect to the database');
  print STDERR "\n\n" if -t STDERR;
  $help = 1;
};

if ($help) {
  help();
  exit 0;
}

unless ( -f '/etc/mailname') {
  info( ERROR => "mailname file doesn't exist - server config seems weird");
  exit 1;
}
open my $fh, '<', '/etc/mailname' or die "Failed to open mailname file";
my $mailhost = <$fh>;
chomp $mailhost;
close $fh;
unless ($mailhost) {
  info(ERROR => "the content of mailname file doesnt't seem right");
  exit 1;
}
info( HEAD => "Checking domains in '$mailhost'");

my @domains = get_domains();
my $cnt = scalar @domains;
my $cur = 0;
for my $dom ( @domains ) {
  $cur++;
  check_domain( $dom );
}
print STDERR "\n\n" if -t STDERR;

sub check_domain {
  my ($domain) = @_;

  info( GROUP => "checking $domain [$cur/$cnt]");
  check_mx( $domain );

  my @txts = rr( $domain, 'TXT' );
  check_spf( $domain, @txts );
  print_dns( @txts );

  check_dkim( $domain );
  check_dmarc( $domain );
}

sub check_spf {
  my ($domain, @txts) = @_;

  my $found = find_in_dns( qr{spf1}, @txts );
  if ( $found ) {
    info( OK => "found a spf1 record for $domain");
  } else {
    info( WARN => "SPF1 record NOT found for $domain");
    email( $domain => "SPF1 record not found for $domain" );
  }
}

sub check_mx {
  my ($domain) = @_;

  my @mxs = mx( $domain );
  my $found = find_in_dns( $mailhost, @mxs );
  if ($found) {
    info( OK => " $mailhost is an MX for $domain ");
  } else { 
    info( WARN => " $mailhost is NOT a MX for $domain");
    email( $domain => "$mailhost is not a MX for $domain");
  }

  print_dns( @mxs );

  return;
}

sub check_dmarc {
  my ($domain) = @_;

  my $dnskey = "_dmarc.$domain";
  my $res   = Net::DNS::Resolver->new;
  $res->udppacketsize( 1280 - 40 );
  my $reply = $res->search( $dnskey => 'TXT');
  my @txt = $reply->answer if $reply;

  unless ($reply and scalar @txt) {
    info( WARN => "DNS '$dnskey' is missing" );
    print STDERR "query failed: ", $res->errorstring,"\n" if -t STDERR;
    email( $domain => "DNS dmarc '$dnskey' is missing");
    info( MISS => "_dmarc\tIN\tTXT\t(\"v=DMARC1; p=none; pct=100; fo=1; \"\n"
                 ."\t\t\t\t\"rua=mailto:dmarc\@$domain\" );" );
    return;
  }

  info( OK  => "dmarc '$dnskey' is set" );
  print_dns( @txt );

  # TODO(maybe): check the dmarc components

  return;
}

sub check_dkim {
  my ($domain) = @_;

  my $dkim = get_dkimkey( $domain );
  unless ( $dkim ) {
    info( WARN => " dkim config missing for $domain");
    email( $domain => "dkim config is missing for $domain");
    return;
  }

  my $selector = $dkim->{selector};
  info( OK  => "dkim configured with selector '$selector'");
  
  my $dnskey = "$selector._domainkey.$domain";
  my $res   = Net::DNS::Resolver->new;
  $res->udppacketsize( 1280 - 40 );
  my $reply = $res->search( $dnskey => 'TXT');
  my @txt = $reply->answer if $reply;
  unless ( $reply and scalar @txt ) {
    info(WARN => "DNS domainkey '$dnskey' is missing");
    print STDERR "query failed: ", $res->errorstring,"\n" if -t STDERR;
    email($domain => "DNS domainkey '$dnskey' is missing");
    info(MISS => $dkim->{txt_record});
    return;
  }

  info( OK => "domainkey '$dnskey' is set" );
  print_dns( @txt );

  my $txtdata;
  for my $txt (@txt) {
    next unless $txt and $txt->can('txtdata');
    for my $text ($txt->txtdata) {
      $txtdata .= ''.ref $text? $text->value : $text;
    }
    last;
  }
  if ($txtdata eq $dkim->{txtdata}) {
    info( OK => "DKIM key in the dns match the expected key");

  } else {
    info(WARN => "DKIM key in the DNS is NOT the expected key");
    email($domain => "DKIM key in the DNS is NOT the expected key");
    info(INFO => "found: $txtdata");
    info(INFO => "expected: $dkim->{txtdata}");
    INFO(MISS => $dkim->{txt_record});
  }

  return; 
}

sub print_dns {
  my (@recs) = @_;

  return unless $verbose;
  for my $rec ( @recs ) {
    info( INFO => $rec->string );
  }
}

sub find_in_dns {
  my ($tofind, @recs) = @_;

  for my $rec (@recs) {
    my $str = '';

    if ( $rec->can('exchange') ) {
      $str = ''.$rec->exchange;
    } elsif ( $rec->can('txtdata') ) {
      $str = ''.$rec->txtdata;
    }
    if ($str) {
      if (ref $tofind) {
        return 1 if $str =~ $tofind;
      } else {
        return 1 if $str eq $tofind;
      }
    }

    unless ( $str and -t STDERR ) {
      use Data::Dumper;
      print STDERR "--not sure what to do with: ",Dumper( $rec );
    }
  }

  return 0;
}

sub get_dkimkey {
  my ($domain) = @_;

  state $keytable;
  unless ($keytable) {
    $keytable = _load_dkim_keytable();
  }
 
  my $keyinfo = $keytable->{ $domain };
  if ( $keyinfo ) {
    _load_dkim_dnskey( $keyinfo );
  }

  return $keyinfo;
}

sub _load_dkim_dnskey {
  my ($dkiminfo) = @_;
  return unless $dkiminfo;
  
  my $fname = $dkiminfo->{keypath};
  $fname =~ s{\.private\z}{.txt};

  open my $fh, '<', $fname
    or do {
      my ($domain) = $dkiminfo->{domain};
      my ($sfname) = $fname =~ m{/([^/]+)\z};
      info(WARN => "Failed to open TXT file '$sfname'");
      info(INFO => " -> '$fname'");
      email($domain => "Failed to open TXT file:\n -> '$fname'");
    };

  my $txt = '';
  my $value = '';
  while (my $ln = <$fh>) {
    next if $ln =~ m{\A\-\-};

    $txt .= $ln;
    my (undef,$val) = split /"/, $ln;

    $value .= $val if $val;
  }

  $dkiminfo->{txt_record} = $txt if $txt;
  $dkiminfo->{txtdata} = $value if $value;

  return;
}

sub _load_dkim_keytable {
  my %table = ();
  open my $fh, '<', '/etc/opendkim/KeyTable'
    or die "Error reading opendkim key table";
 
  while (my $ln= <$fh>) {
    next if $ln =~ m{\A\s*\z};
    next if $ln =~ m{\A\s*\#};
    $ln =~ s{\#.*}{};
    chomp $ln;

    my ($dns, $keydef) = split /\s+/, $ln;
    my ($domain,$selector,$keypath) = split /:/, $keydef;

    $table{$domain} = {
        dns_key   => $dns,
        selector  => $selector,
        domain    => $domain,
        keypath   => $keypath,
      }
  }

  return \%table;
}

sub get_domains {
  my $dbh = get_dbh();

  my $domains = $dbh->selectall_arrayref(<<EoQ);
SELECT domain FROM domain WHERE domain<>'ALL' AND active='1'
EoQ
  
  my @domains = map { $_->[0] } @$domains;

  return @domains;
}

sub get_dbh {
  state $dbh;

  $dbh ||= DBI->connect(
              "DBI:mysql:database=$database;host=$dbhost",
              $dbuser,
              $dbpass,
              { RaiseError => 1 }
            );
}

sub init {
  my $askpassword = undef;
  GetOptions(
    'config_file=s' => \$config_file,
    'database=s'    => \$database,
    'hostname=s'    => \$dbhost,
    'user_db=s'     => \$dbuser,
    'password'      => \$askpassword,
    'verbose'       => \$verbose,
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
    }
  }

  $database ||= $defaults{database};
  $dbhost   ||= $defaults{dbhost};
  $dbuser   ||= $defaults{dbuser};

  if ( $askpassword ) {
    print "Please type the password for '$dbuser\@$dbhost\[$database]': ";
    $dbpass = <>;
    chomp($dbpass);
  }
  $dbpass ||= $ENV{DB_POSTFIX_PASSWORD}
    if $ENV{DB_POSTFIX_PASSWORD};

  return;
}

sub help {
  print STDERR <<EoH;
$0 get a list of domains to check from the postfix database and checks
  if the current host is one of the mx and if SPF, DKIM and DMARC
  are properly configured for each of the domains.

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

  --verbose           - print the DNS records checked
EoH
}

sub email {
  my ($group, $text) = @_;

  return if -t STDERR;

  state $head_done;
  unless ($head_done) {
    my $date = get_date();
    print STDERR <<EOH;
Domain Check Report for $mailhost at $date

*** Issues were found

EOH
    $head_done = 1;
  }

  state $last_group ||= '';

  if ($last_group and $group ne $last_group) {
    print STDERR "\n------------------------------\n"; 
  }

  if ($group and $group ne $last_group) {
    print STDERR "\n>>>>>>>>> $group <<<<<<<<<<<\n\n";
  }
  print STDERR "* $text\n";

  $last_group = $group;
}

sub get_date {
  my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
  $year += 1900;
  $mon  += 1;
  $mon  = "0$mon" if $mon < 10;
  $mday = "0$mday" if $mday < 10;
  $hour = "0$hour" if $hour < 10;
  $min  = "0$min"  if $min < 10;
  return "$year/$mon/$mday $hour:$min";
} 

sub info {
  my ($type, $text) = @_;

  return unless -t STDERR;
  return if $type eq 'INFO' and !$verbose;

  my $color = {
    OK      => 'reset',
    HEAD    => 'bold yellow',
    GROUP   => 'bold blue',
    WARN    => 'yellow',
    ERROR   => 'red',
    INFO    => 'cyan',
    MISS    => 'red',
  }->{$type} || 'reset';

  my $prefix = {
    OK      => ' ',
    GROUP   => '>> ',
    HEAD    => "\n",
    WARN    => ' !! ',
    ERROR   => 'ERROR: ',
    INFO    => "\t",
    MISS    => "Missing:\n",
  }->{$type}||'';

  my $suffix  = {
    OK      => colored(['bold green'], ' [OK]'),
    WARN    => ' !! ',
    HEAD    => "\n",
    MISS    => "\n",
  }->{$type}||'';

  $prefix = $type unless $prefix or $suffix;

  print STDERR "\n" if $type eq 'GROUP';
  print STDERR colored([$color], "$prefix$text$suffix"), "\n";
}
