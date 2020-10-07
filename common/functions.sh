#!/bin/bash

set +e

say() {
  COLOR=$1
  MSG=$2

  echo -e "$COLOR$MSG$NOCOLOR"
}

create_directory() {
  DIR=$1
  OWNER=${2:-root}
  MODE=${3:-755}

  if [ ! -d $DIR ]; then

    say $YELLOW " -- creating $DIR"
    mkdir -p $DIR
    chown $OWNER $DIR
    chmod $MODE $DIR

  fi

}

function render_file() {
  SOURCE=$1
  TARGET=$2

  SOURCE="$OPENOPS_MAIL_DIR/config-files/$SOURCE"

  say $YELLOW " -- rendering '$TARGET'"
  envsubst $OPENOPS_MAIL_VARIABlES <$SOURCE >$TARGET

}
