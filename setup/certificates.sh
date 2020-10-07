#!/bin/bash

set -e

say $BLUE ">> Setting up certificates"

say $YELLOW " -- testing if DNS is right"
TEST_KEY=$(pwgen 62 1)

pushd $MAIL_DIR/htdocs
echo $TEST_KEY >http-only/$PFADMIN_HOSTNAME/.well-known/testfile

echo $TEST_KEY >http-only/$WEBMAIL_HOSTNAME/.well-known/testfile

echo $TEST_KEY >http-only/$MX_HOSTNAME/.well-known/testfile

DNS_FAILED="NO"
INVALUD_HOSTS=""
set +e

wget -O - -q --retry-connrefused http://$PFADMIN_HOSTNAME/.well-known/testfile

if [ ! $? -eq 0 ]; then
  INVALID_HOSTS=$PFADMIN_HOSTNAME
  DNS_FAILED="YES"
fi

wget -O - -q --retry-connrefused http://$WEBMAIL_HOSTNAME/.well-known/testfile
if [ ! $? -eq 0 ]; then
  INVALID_HOSTS="$INVALID_HOSTS $WEBMAIL_HOSTNAME"
  DNS_FAILED="YES"
fi

wget -O - -q --retry-connrefused http://$MX_HOSTNAME/.well-known/testfile
if [ ! $? -eq 0 ]; then
  INVALID_HOSTS="$INVALID_HOSTS $MX_HOSTNAME"
  DNS_FAILED="YES"
fi

set -e

if [ "$DNS_FAILED" = "YES" ]; then

  MYIP=$(wget -q -O- https://api.ipify.org)

  say $RED "!!!!! DNS seems wrong for some hostnames"
  say $YELLOW "  !!!  please set them up\n\n"
  for host in $INVALID_HOSTS; do
    say $YELLOW "  $host \tIN \tA \t$MYIP"
  done
  
  say $YELLOW "\n\nI can't request the certificates without this settings\n\n"

  exit 1;
fi

say $YELLOW " -- Requesting certificate for $WEBMAIL_HOSTNAME"
certbot certonly --webroot -n --agree-tos \
          -m $WEBMASTER_EMAIL \
          -w $MAIL_DIR/htdocs/http-only/$WEBMAIL_HOSTNAME/ -d $WEBMAIL_HOSTNAME

say $YELLOW " -- Requesting certificate for $PFADMIN_HOSTNAME"
certbot certonly --webroot -n --agree-tos \
          -m $WEBMASTER_EMAIL \
          -w $MAIL_DIR/htdocs/http-only/$PFADMIN_HOSTNAME/ -d $PFADMIN_HOSTNAME

say $YELLOW " -- Requesting certificate for $MX_HOSTNAME"
certbot certonly --webroot -n --agree-tos \
          -m $WEBMASTER_EMAIL \
          -w $MAIL_DIR/htdocs/http-only/$MX_HOSTNAME/ -d $MX_HOSTNAME

say $BLUE " ++ Done with certificates"
