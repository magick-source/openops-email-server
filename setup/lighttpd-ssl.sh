#!/bin/bash

set -e

say $BLUE ">> Setting up lighttpd SSL - needed certs for this"

if [ ! -d $MAIL_DIR/htdocs/default-ssl ]; then
  mkdir -p $MAIL_DIR/htdocs/default-ssl
fi

render_file lighttpd/10-ssl.conf \
            /etc/lighttpd/conf-enabled/10-ssl.conf

render_file lighttpd/50-pfadmin.conf \
            /etc/lighttpd/conf-enabled/50-pfadmin.conf

render_file lighttpd/50-webmail.conf \
            /etc/lighttpd/conf-enabled/50-webmail.conf

say $BLUE " ++ done with lighttpd ssl configs\n\n"
