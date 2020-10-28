#!/bin/bash

set -e

GRANTS_NEED_FIXED=0

function pfadmin_grant_all {

  GRANTS_NEED_FIXED=1
  say $CYAN " ** temporarily granting all to postfixadmin"

  mariadb <<EoQ

GRANT ALL on $DB_POSTFIX.*
  TO 'postfixadmin'@'localhost'

EoQ

}

function pfadmin_fix_grants {
  mariadb <<EoQ

REVOKE ALL on $DB_POSTFIX.* FROM 'postfixadmin'@'localhost';

GRANT INSERT,DELETE,UPDATE,SELECT
  on $DB_POSTFIX.*
  TO 'postfixadmin'@'localhost';

EoQ

  GRANTS_NEED_FIXED=0

  say $CYAN " ** grant all to postfixadmin REVOKED"  
}

say $BLUE ">> Set up postfixadmin"

SETUP_OUT=$(wget --retry-connrefused \
                  https://$PFADMIN_HOSTNAME/setup.php -O - )


set +e # grep return 1 if no match is made
HAVE_DEBUG=$(echo $SETUP_OUT | grep DEBUG )
if [ $? -eq 1 ]; then
  HAVE_DEBUG=""
fi
set -e



if [ "$HAVE_DEBUG" != "" ]; then

  pfadmin_grant_all

  say $YELLOW " -- updating postfixadmin database"

  SETUP_OUT=$(wget -q --retry-connrefused \
                  https://$PFADMIN_HOSTNAME/setup.php -O - )

  set +e
  DBUPDATES=$(echo $SETUP_OUT | grep "updating to version")
  set -e

  if [ "$DBUPDATES" != "" ]; then

    DBUPDATES=$( echo $SETUP_OUT \
                  | sed 's/.*Updating database:<\/p>//' \
                  | sed 's/<p>/\\n\n/g' | sed 's/<\/p>/\\n\n/' \
                  | sed 's/<div/\n/g' | sed 's/&nbsp;/ /g' \
                  | grep -v div )

    say $CYAN "*** postfix database updates"
    echo $DBUPDATES | sed 's/\\n/\n/g'
    echo "\n\n"

  fi

  say $YELLOW " ++ done updating postfixadmin database"
fi

SETUP_DONE=0

set +e
NEEDS_SUPERDAMIN=$(echo $SETUP_OUT | grep "Create superadmin account")
set -e
if [ $? -eq 0 ]; then

  if [ $GRANTS_NEED_FIXED -eq 0 ]; then
    pfadmin_grant_all
  fi

  say $YELLOW " -- creating superadmin account"

  POSTDATA="form=createadmin&setup_password=$PFADMIN_SETUPPW"
  POSTDATA="$POSTDATA&username=$PFADMIN_ADMINEMAIL"
  POSTDATA="$POSTDATA&password=$PFADMIN_PASSWORD"
  POSTDATA="$POSTDATA&password2=$PFADMIN_PASSWORD"
  SETUP_OUT=$(wget -q --post-data="$POSTDATA" \
                  https://$PFADMIN_HOSTNAME/setup.php -O - )
  
  set +e
  CREATED=$(echo $SETUP_OUT|grep "done with your basic setup")
  if [ ! $? -eq 0 ]; then
    EXISTED=$(echo $SETUP_OUT|grep "admin already exists")
    if [ $? -eq 0 ]; then
      SETUP_DONE=1
    fi
  else
    SETUP_DONE=1
  fi

fi

if [ $GRANTS_NEED_FIXED -eq 1 ]; then
  pfadmin_fix_grants
fi

if [ ! $SETUP_DONE -eq 1 ]; then
  echo "SETUP-OUT: $SETUP_OUT"
  say $RED  "\n\n ** ERROR **"
  say $RED  " ** Something went wrong setting up postfix admin **"
  say $CYAN " >> visit https://$PFADMIN_HOSTNAME/setup.php to find out more"
  say $RED  " ** ERROR **\n\n"

else
  say $BLUE " ++ done with postfixadmin"

fi

