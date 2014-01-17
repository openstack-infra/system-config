#!/bin/bash

flock /tmp/er_safe_run.lock $@
