#!/bin/bash

set -e

say $BLUE ">> Setting up postfix/dovecot config files"

render_file postfix/main.cf /etc/postfix/main.cf

render_file postfix/dynamicmaps.cf /etc/postfix/dynamicmaps.cf

render_file postfix/master.cf /etc/postfix/master.cf

render_file postfix/mysql-virtual_domains.cf \
            /etc/postfix/mysql-virtual_domains.cf

render_file postfix/mysql-virtual_email2email.cf \
            /etc/postfix/mysql-virtual_email2email.cf


render_file postfix/mysql-virtual_forwardings.cf \
            /etc/postfix/mysql-virtual_forwardings.cf

render_file postfix/mysql-virtual_mailbox_limit_maps.cf \
            /etc/postfix/mysql-virtual_mailbox_limit_maps.cf

render_file postfix/mysql-virtual_mailboxes.cf \
            /etc/postfix/mysql-virtual_mailboxes.cf

render_file postfix/mysql-virtual_transports.cf \
            /etc/postfix/mysql-virtual_transports.cf

render_file postfix/sasl-smtpd.conf \
            /etc/postfix/sasl/smtpd.conf

render_file dovecot/dovecot.conf \
            /etc/dovecot/dovecot.conf

render_file dovecot/dovecot-sql.conf.ext \
            /etc/dovecot/dovecot-sql.conf.ext

say $BLUE " ++ done with postfix/dovecot config\n\n" 


# /etc/lighttpd/conf-enabled/00-fastcgi.conf

# /etc/lighttpd/conf-enabled/50-pfadmin.conf

# /etc/lighttpd/conf-enabled/50-webmail.conf


