#!/bin/bash

set -e

say $BLUE "\n\n\n>> Installing/Updating debian packages";

say $YELLOW " -- updating repo indexes"
apt-get update

say $YELLOW "\n\n -- Installing Basic Stuff"
apt-get -y install fail2ban wget openssh-server pwgen

say $YELLOW "\n\n -- Installing MariaDB"
apt-get -y install mariadb-server mariadb-client

say $YELLOW "\n\n -- Installing lighttpd and php for webmail"
apt-get -y install lighttpd php-cgi php-intl php-mysql php-imap

say $YELLOW "\n\n -- Installing postfix and dovecot"
apt-get -y install postfix postfix-mysql \
           dovecot-lmtpd dovecot-mysql dovecot-pop3d \
           dovecot-imapd dovecot-sieve dovecot-managesieved \
           postfix-policyd-spf-perl

say $YELLOW "\n\n -- Installing antispam and antivirus"
apt-get -y install spamassassin spamc clamav

say $YELLOW "\n\n -- Installting certbox"
apt-get -y install certbot

say $BLUE "\n++ Packages done\n\n";
