#!/bin/bash

export OPENOPS_MAIL_VARIABlES='$MAIL_DIR:$MAIL_HOST:$POSTMASTER_EMAIL:$POSTADMIN_EMAIL:$DB_POSTFIX:$DB_POSTFIX_PASSWORD:$DB_POSTFIXADMIN_PASSWORD:$DB_DEVECOT_PASSWORD:$DB_ROUNDCUBE:$DB_ROUNDCUBE_PASSWORD:$MX_HOSTNAME:$MX_MYNETWORKS:$DB_DOVECOT_PASSWORD:$COOKIEKEY_ROUNDCUBE:$PFADMIN_HOSTNAME:$PFADMIN_SETUP_CHECK:$MX_MAIN_DOMAIN:$WEBMAIL_HOSTNAME'

echo -e "$BLUE>> Checking configs$NOCOLOR"

if [ -f "$HOME/.openops_mail.cfg" ]; then

  echo -e "$YELLOW -- config file found. loading$NOCOLOR"
  . $HOME/.openops_mail.cfg

else

  echo -e "$YELLOW -- config file not found. creating$NOCOLOR"

  echo -e "$RED TODO: ask for the config variables and store in file$NOCOLOR"
  exit 1;
fi

echo -e "$BLUE MAIL_DIR=$YELLOW$MAIL_DIR$NOCOLOR"
echo -e "$BLUE MAIL_HOST=$YELLOW$MAIL_HOST$NOCOLOR"


