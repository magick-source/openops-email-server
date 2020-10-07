#!/bin/bash

set -e

today=${TODAY:-$(date +%Y%m%d)}

echo -e "$BLUE>> Installing PostFixAdmin$NOCOLOR"

if [ -d /tmp/postfixadmin ]; then
  # delete old files
  for fn in /tmp/postfixadmin/pfadmin-*.tgz; do
    if [[ ! $fn == *$today* ]]; then
      echo -e "$RED ==> old file: $fn - deleting$NOCOLOR"
      rm $fn
    fi
  done

else
  mkdir /tmp/postfixadmin
fi


pfadmin_tgz=/tmp/postfixadmin/pfadmin-$today.tgz

if [ -f $pfadmin_tgz ]; then
  echo -e "$YELLOW -- postfixadmin downloaded today - reusing$NOCOLOR"

else
  echo -e "$YELLOW -- downloading postfixadmin$NOCOLOR"
  wget -nv -O /tmp/postfixadmin/pfadmin-$today.tgz \
    http://sourceforge.net/projects/postfixadmin/files/latest/download
fi

echo -e "$YELLOW -- copying to sister directory$NOCOLOR"

mkdir $MAIL_DIR/htdocs/pfadmin-new
pushd $MAIL_DIR/htdocs/pfadmin-new

tar --strip-components=1 --no-same-owner -zxf $pfadmin_tgz

# templates_c needs to be writable for smarty templates cache
mkdir templates_c
chmod -R 777 templates_c

render_file pfadmin/config.inc.php \
            $MAIL_DIR/htdocs/pfadmin-new/config.inc.php

cd $MAIL_DIR/htdocs

if [ -d pfadmin-old ]; then
  echo -e "$YELLOW -- deleting older old directory$NOCOLOR"
  rm -rf pfadmin-old
fi

echo -e "$YELLOW -- switching pfadmin directories$NOCOLOR"
if [ -d pfadmin ]; then
  mv pfadmin pfadmin-old
fi
mv pfadmin-new pfadmin

popd

echo -e "$BLUE ++ postfixadmin done$NOCOLOR\n\n"

