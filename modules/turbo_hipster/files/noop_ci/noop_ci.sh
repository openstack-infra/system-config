#!/bin/bash -e

#./$0 %(git_path)s %(job_working_dir)s %(unique_id)s

export GIT_PATH=$1
export JOB_WORKING_DIR=$2
export UNIQUE_ID=$3

echo "noop"

exit 0
