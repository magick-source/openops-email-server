#!/bin/bash

set -e

say $BLUE ">> Setting up lighttpd"

render_file lighttpd/00-fastcgi.conf \
            /etc/lighttpd/conf-enabled/00-fastcgi.conf

if [ ! -d $MAIL_DIR/htdocs/http-only ]; then
  mkdir -p $MAIL_DIR/htdocs/http-only/$PFADMIN_HOSTNAME/.well-known
  mkdir -p $MAIL_DIR/htdocs/http-only/$WEBMAIL_HOSTNAME/.well-known
  mkdir -p $MAIL_DIR/htdocs/http-only/$MX_HOSTNAME/.well-known
fi

render_file lighttpd/10-http-only.conf \
            /etc/lighttpd/conf-enabled/10-http-only.conf

render_file lighttpd/redirect-to-ssl-index.php \
            $MAIL_DIR/htdocs/http-only/$PFADMIN_HOSTNAME/index.php

render_file lighttpd/redirect-to-ssl-index.php \
            $MAIL_DIR/htdocs/http-only/$WEBMAIL_HOSTNAME/index.php

say $YELLOW " -- restarting lighttpd to reload configs"

/etc/init.d/lighttpd restart

say $BLUE " ++ done with lighttpd configs\n\n"
