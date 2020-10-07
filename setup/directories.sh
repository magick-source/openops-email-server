#!/bin/bash

set -e

echo -e "$BLUE>> Creating directories under '$MAIL_DIR'$NOCOLOR";

create_directory $MAIL_DIR

create_directory $MAIL_DIR/htdocs/pfadmin

create_directory $MAIL_DIR/htdocs/webmail

create_directory $MAIL_DIR/mail vmail

echo -e "$BLUE ++ directories created$NOCOLOR\n\n"

