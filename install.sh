#!/bin/sh

set -e

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
RED='\033[0;31m'


# checking if we are in a debian
if [ ! -f /etc/debian_version ]; then

  echo "${RED}ERROR: This install file was created for debian$NOCOLOR"
  echo "$YELLOW  * this doesn't seem to be running in debian.$NOCOLOR"
  echo "$YELLOW  Bailing out!!$NOCOLOR"

  exit 1;
fi

debian_version=$( cat /etc/debian_version )

echo -e "$BLUE >> Running in Debian $YELLOW$debian_version$NOCOLOR\n\n"

echo "$BLUE >> Installing dependenvies$NOCOLOR"
apt-get -y install git


