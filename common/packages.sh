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

say $YELLOW "\n\n -- Installing antispam and antivirus"
apt-get -y install spamassassin spamc clamav

say $YELLOW "\n\n -- Installting certbox"
apt-get -y install certbot

say $BLUE "\n++ Packages done\n\n";
