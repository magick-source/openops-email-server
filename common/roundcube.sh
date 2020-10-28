#!/bin/bash

set -e

today=${TODAY:-$(date +%Y%m%d)}

say $BLUE ">> Installing Roundcube"

if [ -d /tmp/roundcube ]; then
  # delete old files
  for fn in /tmp/roundcube/roundcube-*; do
    if [[ ! $fn == *$today* ]]; then
      say $RED " ==> old file: $fn - deleting"
      rm $fn
    fi
  done
else
  mkdir /tmp/roundcube
fi

rc_zip=/tmp/roundcube/roundcube-$today.zip

if [ -f $rc_zip ]; then
  say $YELLOW " -- roundube downloaded today - reusing"

else
  say $YELLOW " -- downloading roundcube"
  wget -nv -O $rc_zip \
    https://github.com/roundcube/roundcubemail/archive/master.zip
fi

say $YELLOW " -- copying to sister directory"

if [ -d $MAIL_DIR/htdocs/webmail-new ]; then
  say $YELLOW " -- $MAIL_DIR/htdocs/webmail-new exists." 
  echo -n -e "$YELLOW >>> Can I remove it? (Y/n) $NOCOLOR"
  read DROP_DIR
  if check_yesno $DROP_DIR; then
    rm -rf $MAIL_DIR/htdocs/webmail-new
    say $CYAN " ++ Old webmail-new dir dropped - continuing"

  else
    say $RED " Can't continue without deleting the directory. Bailling out!"
    exit 1
  fi
fi

mkdir $MAIL_DIR/htdocs/webmail-new
pushd $MAIL_DIR/htdocs/webmail-new

unzip -q $rc_zip -d .
mv ./roundcubemail-master/* .
rm -rfv roundcubemail-master

render_file roundcube/config.inc.php \
            $MAIL_DIR/htdocs/webmail-new/config/config.inc.php

say $YELLOW " -- Installing php dependencies"
mv composer.json-dist composer.json
composer install --no-plugins --no-scripts --no-dev

say $YELLOW " -- Installing javascript dependencies"
bin/install-jsdeps.sh

cd $MAIL_DIR/htdocs

if [ -d webmail-old ]; then
  say $YELLOW " -- deleting older old directory"
  rm -rf webmail-old
fi

say $YELLOW " -- switching webmail directories"
if [ -d webmail ]; then
  mv webmail webmail-old
fi
mv webmail-new webmail

say $YELLOW " -- creating tables for roundcube"

cd webmail
set +e
ERROR=$($MAIL_DIR/htdocs/webmail/bin/initdb.sh \
            --dir $MAIL_DIR/htdocs/webmail/SQL/ )
set -e
if [ ! $? -eq 0 ]; then
  say $YELLOW " -->> tables exist - updating them"
  $MAIL_DIR/htdocs/webmail/bin/initdb.sh --version=?
fi


popd

create_directory $MAIL_DIR/temp/roundcube www-data

say $BLUE " ++ roundcube installed\n\n"

