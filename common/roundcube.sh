#!/bin/bash

set +e

today=${TODAY:-$(date +%Y%m%d)}

echo -e "$BLUE>> Installing Roundcube$NOCOLOR"

if [ -d /tmp/roundcube ]; then
  # delete old files
  for fn in /tmp/roundcube/roundcube-*.tgz; do
    if [[ ! $fn == *$today* ]]; then
      echo -e "$RED ==> old file: $fn - deleting$NOCOLOR"
      rm $fn
    fi
  done
else
  mkdir /tmp/roundcube
fi

rc_tgz=/tmp/roundcube/roundcube-$today.tgz

if [ -f $rc_tgz ]; then
  echo -e "$YELLOW -- roundube downloaded today - reusing$NOCOLOR"

else
  echo -e "$YELLOW -- downloading roundcube$NOCOLOR"
  wget -nv -O $rc_tgz \
    http://sourceforge.net/projects/roundcubemail/files/latest/download
fi

echo -e "$YELLOW -- copying to sister directory$NOCOLOR"

mkdir $MAIL_DIR/htdocs/webmail-new
pushd $MAIL_DIR/htdocs/webmail-new

tar --strip-components=1 --no-same-owner -zxf $rc_tgz

render_file roundcube/config.inc.php \
            $MAIL_DIR/htdocs/webmail-new/config/config.inc.php

cd $MAIL_DIR/htdocs

if [ -d webmail-old ]; then
  echo -e "$YELLOW -- deleting older old directory$NOCOLOR"
  rm -rf webmail-old
fi

echo -e "$YELLOW -- switching webmail directories$NOCOLOR"
if [ -d webmail ]; then
  mv webmail webmail-old
fi

mv webmail-new webmail

popd

create_directory $MAIL_DIR/temp/roundcube www-data

create_directory $MAIL_DIR/logs/roundcube www-data

# TODO: configurations for roundcube

echo -e "$BLUE ++ roundcube installed$NOCOLOR\n\n"

