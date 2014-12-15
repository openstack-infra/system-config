#!/bin/bash

# non blocking lock, send KILL signal after 40 minutes, kill after 45 minutes
flock -n /var/lib/elastic-recheck/er_safe_run.lock timeout -k 40m 45m $@
