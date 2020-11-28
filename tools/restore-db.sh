#!/bin/bash

set -e

BASEDIR=$(dirname "$0")

pushd "$BASEDIR/../"

BASEDIR=$(pwd)

popd

export DB_PFRESTORER_PWD=$(pwgen 16 1)

source "$BASEDIR/common/functions.sh"
if [ -f ~/.openops_mail.cfg ]; then
  source ~/.openops_mail.cfg
fi

DATA_DIR=${1:-$OPENMAIL_CFG_DATADIR}
if [ -z $DATA_DIR ]; then
  say $RED "the data dir to be restore was not passed";
  say $YELLOW "Usage: $0 <data_dir>"
  echo -e "\n\n"
  exit 1;
fi

DB_POSTFIX=${DB_POSTFIX:-postfix}

say $BLUE ">> Creating restorer db username for '$DB_POSTFIX'";
mariadb <<EoQ
GRANT DROP,INSERT,SELECT,DELETE,UPDATE ON $DB_POSTFIX.*
  TO 'pfrestorer'@'localhost'
  IDENTIFIED by '$DB_PFRESTORER_PWD'

EoQ

say $BLUE ">> Restoring config data"
$BASEDIR/tools/restore-db.pl -b "$DATA_DIR" -u pfrestorer -r -vvv

say $BLUE " ++ done\n\n"
say $BLUE " -- Removing db user"
mariadb <<EoQ
REVOKE ALL ON $DB_POSTFIX.*
  FROM 'pfrestorer'@'localhost'

EoQ

say $YELLOW "ALL DONE!"

