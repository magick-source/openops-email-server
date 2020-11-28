#!/bin/bash

set -e

say $BLUE "\n\n\n>> Installing/Updating debian packages";

say $YELLOW " -- updating repo indexes"
apt-get update

say $YELLOW "\n\n -- Installing Basic Stuff"
apt-get -y install fail2ban wget openssh-server pwgen unzip

say $YELLOW "\n\n -- Installing MariaDB"
apt-get -y install mariadb-server mariadb-client

say $YELLOW "\n\n -- Installing lighttpd and php for webmail"
apt-get -y install lighttpd php-cgi \
           php-auth-sasl php-net-idna2 php-net-smtp \
           php-intl php-mysql php-imap php-mbstring \
           php-xml php-pear php-zip php-mail-mime \
           php-gd composer 

say $YELLOW "\n\n -- Installing postfix and dovecot"
apt-get -y install postfix postfix-mysql \
           dovecot-lmtpd dovecot-mysql dovecot-pop3d \
           dovecot-imapd dovecot-sieve dovecot-managesieved \
           postfix-policyd-spf-perl postgrey

say $YELLOW "\n\n -- Installing opendkim"
apt-get -y install opendkim opendkim-tools

say $YELLOW "\n\n -- Installing antispam"
apt-get -y install spamassassin spamc

say $YELLOW "\n\n -- Installing compression tools for antivirus"
apt-get -y install arj bzip2 cabextract cpio rpm2cpio file gzip \
           lhasa nomarch pax p7zip-full unzip zip lrzip \
           lzip liblz4-tool lzop unrar-free xz-utils unar

say $YELLOW "\n\n -- Installing antivirus"
# amavis fails to start if it doesn't have a fqhn,
# and you can set one in 05-node_id file, so let's do that
# otherwise apt-get may fail here!
if [ ! -f /etc/amavis/conf.d/05-node_id ]; then
  create_directory /etc/amavis/conf.d
  render_file amavis/05-node_id \
              /etc/amavis/conf.d/05-node_id
fi
apt-get -y install clamav amavisd-new

say $YELLOW "\n\n -- Installting certbox"
apt-get -y install certbot

say $YELLOW "\n\n -- Installing tools dependencies"
apt-get -y install libtext-csv-perl libconfig-tiny-perl 

say $BLUE "\n++ Packages done\n\n";
