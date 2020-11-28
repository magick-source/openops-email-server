#!/bin/bash

set -e

say $BLUE ">> Setting up log summary crons"

render_file 'cronjobs/pflogsumm' '/etc/cron.d/pflogsumm'

say $YELLOW " -- reloading crontabs"
/etc/init.d/cron reload

say $BLUE "++ log summary crons done"
