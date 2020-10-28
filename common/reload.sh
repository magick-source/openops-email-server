#!/bin/bash

set -e

say $BLUE ">> Reloading/restarting services to update configs"

postalias /etc/aliases

/etc/init.d/postfix restart

/etc/init.d/dovecot restart

/etc/init.d/spamassassin restart

/etc/init.d/lighttpd restart

say $BLUE " ++ Done reloading\n\n"
