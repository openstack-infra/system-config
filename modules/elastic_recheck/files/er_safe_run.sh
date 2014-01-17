#!/bin/bash

flock /var/lib/elastic-recheck/er_safe_run.lock $@
