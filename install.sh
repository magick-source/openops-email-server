#!/bin/bash

set -e
# set -x

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
RED='\033[0;31m'

OPENOPS_MAIL_GIT=${OPENOPS_MAIL_GIT:-"http://magick-source.net/OpenOps/email-server.git"}
OPENOPS_MAIL_DIR=${OPENOPS_MAIL_DIR:-"/tmp/mail-server"}

check_yesno() {
  RES=$1

  if [ -z $RES ] || [ $RES = 'y' ] || [ $RES = 'Y' ]; then
    return 0
  fi
 
  return 1
}


# checking if we are in a debian
if [ ! -f /etc/debian_version ]; then

  echo -e "${RED}ERROR: This install file was created for debian$NOCOLOR"
  echo -e "$YELLOW  * this doesn't seem to be running in debian.$NOCOLOR"
  echo -e "$YELLOW  Bailing out!!$NOCOLOR"

  exit 1;
fi

debian_version=$( cat /etc/debian_version )
OPENOPS_DEB_VERSION=$debian_version

echo -e "$BLUE>> Running in Debian $YELLOW$debian_version$NOCOLOR\n\n"

echo -e "$BLUE>> Installing dependenvies$NOCOLOR"
apt-get -y install git


echo -e "$BLUE>> Cloning OpenOps Email repo$NOCOLOR"



if [ -d $OPENOPS_MAIL_DIR ]; then
  
  echo -n -e "$YELLOW -- directory exists. Can I remove it? (Y/n) $NOCOLOR"
  read DROP_DIR

  if check_yesno $DROP_DIR; then
    
    echo -e "$BLUE -- Drop the current directory$NOCOLOR"
    rm -rf "$OPENOPS_MAIL_DIR"

  else
    echo -n -e "$YELLOW **** OK. Continue with the current version? (Y/n) $NOCOLOR"
    read USE_DIR
   
    if check_yesno $USE_DIR; then

        echo -e "$BLUE *** OK, moving on!$NOCOLOR"
    else

        echo -e "$RED STOPPING HERE!$NOCOLOR"
        exit 2
    fi

  fi

fi

if [ -d $OPENOPS_MAIL_DIR ]; then

  cd "$OPENOPS_MAIN_DIR"
  git pull --rebase

else

  echo -e "$BLUE -- cloning '$YELLOW$OPENOPS_MAIL_GIT$BLUE'$NOCOLOR"
  git clone "$OPENOPS_MAIL_GIT" "$OPENOPS_MAIL_DIR"

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

# configure postfix and dovecot
source $OPENOPS_MAIL_DIR/setup/postfix-config.sh

# configure webmail and pfadmin hosts
source $OPENOPS_MAIL_DIR/setup/lighttpd-ssl.sh

# reload/restart the services
source $OPENOPS_MAIL_DIR/common/reload.sh

