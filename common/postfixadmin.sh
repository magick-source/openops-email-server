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
  create_directory /tmp/postfixadmin
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

create_directory $MAIL_DIR/htdocs/pfadmin-new
pushd $MAIL_DIR/htdocs/pfadmin-new

tar --strip-components=1 --no-same-owner -zxf $pfadmin_tgz

# templates_c needs to be writable for smarty templates cache
create_directory templates_c www-data 755

PFADMIN_SETUPPW_SALT=$( pwgen 32 1 )
PFADMIN_SETUP_SUM=$(
    echo -n "$PFADMIN_SETUPPW_SALT:$PFADMIN_SETUPPW" \
    | sha1sum - | cut -d ' ' -f 1
  )
export PFADMIN_SETUP_CHECK="$PFADMIN_SETUPPW_SALT:$PFADMIN_SETUP_SUM"

render_file pfadmin/config.local.php \
            $MAIL_DIR/htdocs/pfadmin-new/config.local.php

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

