#!/bin/bash

say $BLUE ">> setting up DKIM base"

create_directory /etc/opendkim/keys

render_file opendkim/opendkim.conf /etc/opendkim.conf
render_file opendkim/defaults /etc/default/opendkim

# We don't want to touch this files if they already exist
# as they are added as needed when keys are added for the domains

if [ ! -e /etc/opendkim/TrustedHosts ]; then
  render_file opendkim/TrustedHosts /etc/opendkim/TrustedHosts
fi

if [ ! -e /etc/opendkim/KeyTable ]; then
  render_file opendkim/KeyTable /etc/opendkim/KeyTable
fi

if [ ! -e /etc/opendkim/SigningTable ]; then
  render_file opendkim/SigningTable /etc/opendkim/SigningTable
fi

/etc/init.d/opendkim reload

say $BLUE " ++ done with DKIM"
