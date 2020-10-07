#!/bin/bash

set -e
set +x 

echo -e "$BLUE>> create databases and db users$NOCOLOR"

echo -e "$YELLOW -- creating database for postfix$NOCOLOR"
mariadb <<EoQ

CREATE DATABASE IF NOT EXISTS $DB_POSTFIX
  CHARACTER SET utf8
  COLLATE utf8_unicode_ci;

-- access to postfix
GRANT SELECT ON $DB_POSTFIX.*
  TO 'postfix'@'localhost'
  IDENTIFIED by '$DB_POSTFIX_PASSWORD';

-- access to postfixadmin
GRANT INSERT,DELETE,UPDATE,SELECT ON $DB_POSTFIX.*
  TO 'postfixadmin'@'localhost'
  IDENTIFIED by '$DB_POSTFIXADMIN_PASSWORD';

-- access to dovecot
GRANT SELECT ON $DB_POSTFIX.*
  TO 'dovecot'@'localhost'
  IDENTIFIED by '$DB_DOVECOT_PASSWORD';

EoQ

echo -e "$YELLOW -- creating database for roundcube webmail$NOCOLOR"
mariadb <<EoQ

CREATE DATABASE IF NOT EXISTS $DB_ROUNDCUBE
  CHARACTER SET utf8
  COLLATE utf8_unicode_ci;

-- access to roundcube
GRANT ALL ON $DB_ROUNDCUBE.*
  TO 'roundcube'@'localhost'
  IDENTIFIED by '$DB_ROUNDCUBE_PASSWORD';

EoQ

echo -e "$BLUE ++ databases created\n\n$NOCOLOR"

