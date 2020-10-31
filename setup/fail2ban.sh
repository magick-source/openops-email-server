#!/bin/bash

set -e

say $BLUE ">> Setting up some more jails on fail2ban"

render_file fail2ban/filter-postfixadmin-auth.conf \
    /etc/fail2ban/filter.d/postfixadmin-auth.conf

render_file fail2ban/jail-postfixadmin-auth.conf \
    /etc/fail2ban/jail.d/postfixadmin-auth.conf

render_file fail2ban/jail-postfix.conf \
    /etc/fail2ban/jail.d/postfix.conf

render_file fail2ban/jail-roundcube.conf \
    /etc/fail2ban/jail.d/roundcube.conf

/etc/init.d/fail2ban reload

say $BLUE " ++ Done with fail2ban"
