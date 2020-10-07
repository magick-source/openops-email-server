#!/bin/sh

set -e

echo -e "$BLUE>> Creating groups and users$NOCOLOR"

# add a group and user for virtual directories
if [ ! $(getent group vmail) ]; then
  groupadd -g 5000 -r vmail
  useradd -g vmail -M -r -u 5000 vmail
fi

# add a group and user for spamd
if [ ! $(getent group spamd) ]; then
  groupadd -g 5001 -r spamd
  useradd -g spamd -M -r -u 5001 spamd

fi

echo -e "$BLUE ++ groups and users done$NOCOLOR\n\n"

