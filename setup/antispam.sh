#!/bin/bash

set -e

say $BLUE '>> Setting up spamassassin'

if [ ! -d $MAIL_DIR/spamassassin ]; then
  mkdir $MAIL_DIR/spamassassin
fi

# spamassassin config
MX_SPAM_TRUST_NETWORKS=${MX_SPAM_TRUST_NETWORKS:-''}
export MX_SPAM_TRUST_NETWORKS

render_file 'spamassassin/local.cf' '/etc/spamassassin/local.cf'
render_file 'spamassassin/defaults' '/etc/default/spamassassin'

say $BLUE "++ spamassassin done\n\n"

