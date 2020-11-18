#!/bin/bash

set -e


say $BLUE "\n>> Setting up the default sieve filters"

pushd $OPENOPS_MAIL_DIR/config-files/sieve/before

create_directory /etc/dovecot/sieve/before.d
for fname in *; do
  render_file sieve/before/$fname /etc/dovecot/sieve/before.d/$fname
  say $YELLOW "  ++ compiling sieve file '$fname'"
  sievec /etc/dovecot/sieve/before.d/$fname
done

popd
pushd $OPENOPS_MAIL_DIR/config-files/sieve/after

create_directory /etc/dovecot/sieve/after.d
for fname in *; do
  render_file sieve/after/$fname /etc/dovecot/sieve/after.d/$fname
  say $YELLOW "  ++ compiling sieve file '$fname'"
  sievec /etc/dovecot/sieve/after.d/$fname
done
popd

say $BLUE " ++ done with sieve filters\n"
