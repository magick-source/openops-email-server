#!/bin/bash

set -e

say $BLUE ">> Setting up amavis"

say $YELLOW " -- adding clamav to amavis group (and viceversa)"
adduser clamav amavis
adduser amavis clamav 

create_directory /servers/amavis/temp amavis
create_directory /servers/amavis/quarantine amavis

render_file amavis/05-node_id \
            /etc/amavis/conf.d/05-node_id

render_file amavis/15-content_filter_mode \
            /etc/amavis/conf.d/15-content_filter_mode

render_file amavis/15-av_scanners \
            /etc/amavis/conf.d/15-av_scanners

render_file amavis/50-user \
            /etc/amavis/conf.d/50-user

render_file amavis/75-local_domains \
            /etc/amavis/conf.d/75-local_domains

say $YELLOW " -- restarting amavis"
/etc/init.d/amavis restart

say $YELLOW " -- restarting clamav-daemon"
/etc/init.d/clamav-daemon restart

say $BLUE " ++ done with amavis"

