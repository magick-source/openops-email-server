#!/bin/bash

set -e
# set -x

# checking if we are in a debian
if [ ! -f /etc/debian_version ]; then

  echo -e "${RED}ERROR: This install file was created for debian$NOCOLOR"
  echo -e "$YELLOW  * this doesn't seem to be running in debian.$NOCOLOR"
  echo -e "$YELLOW  Bailing out!!$NOCOLOR"

  exit 1;
fi

debian_version=$( cat /etc/debian_version )
OPENOPS_DEB_VERSION=$debian_version

# TODO(maybe) = use $0 directory as the default?
OPENOPS_MAIL_DIR=${OPENOPS_MAIL_DIR:-"/tmp/mail-server"}

if [ -d $OPENOPS_MAIL_DIR ]; then

  cd "$OPENOPS_MAIL_DIR"

else
  echo "**** ERROR: Expected OpenOps Mail in $OPENOPS_MAIL_DIR"
  echo "     --- Directory not found"
  echo "you can export OPENOPS_MAIL_DIR=<...> to define where it is"
  exit 1
fi

cd "$OPENOPS_MAIL_DIR"

# just some shared functions
source $OPENOPS_MAIL_DIR/common/functions.sh

# collect configuration
source $OPENOPS_MAIL_DIR/common/settings.sh

# install all the stuff we need from debian
source $OPENOPS_MAIL_DIR/common/packages.sh

# add user groups
source $OPENOPS_MAIL_DIR/setup/create-users.sh

# create directories
source $OPENOPS_MAIL_DIR/setup/directories.sh

# install all the stuff we need from debian
source $OPENOPS_MAIL_DIR/setup/mysql.sh

# install round cube webmail
source $OPENOPS_MAIL_DIR/common/roundcube.sh

# install postfixadmin
source $OPENOPS_MAIL_DIR/common/postfixadmin.sh

# configure lighttpd
source $OPENOPS_MAIL_DIR/setup/lighttpd.sh

# setup certificates
source $OPENOPS_MAIL_DIR/setup/certificates.sh

# configure spamassassin
source $OPENOPS_MAIL_DIR/setup/antispam.sh

# configure amavis
source $OPENOPS_MAIL_DIR/setup/amavis.sh

# configure postfix and dovecot
source $OPENOPS_MAIL_DIR/setup/postfix-config.sh

# configure the sieve filters
source $OPENOPS_MAIL_DIR/setup/sieve-config.sh

# configure webmail and pfadmin hosts
source $OPENOPS_MAIL_DIR/setup/lighttpd-ssl.sh

# reload/restart the services
source $OPENOPS_MAIL_DIR/common/reload.sh

# setup postfixadmin
source $OPENOPS_MAIL_DIR/common/postfixadmin-setup.sh

# setup fail2ban
source $OPENOPS_MAIL_DIR/setup/fail2ban.sh

# setup dkim base
source $OPENOPS_MAIL_DIR/setup/dkim.sh

