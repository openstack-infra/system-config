#!/usr/bin/python3

# Copyright 2018 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# This script parses the logfiles on bridge.o.o to give an overview of
# how long the last "run_all.sh" iterations took and give a clue to
# what might have changed inbetween runs.

from datetime import datetime
import os

# TODO: reverse walk rotated logs for longer history
with open('/var/log/ansible/run_all_cron.log') as f:
    begin = None
    for line in f:
        if "--- begin run @" in line:
            # 2018-09-05T01:10:36+00:00
            begin = datetime.strptime(line[16:-5], '%Y-%m-%dT%H:%M:%S+00:00')
            continue
        if "--- end run @" in line:
            end = datetime.strptime(line[14:-5], '%Y-%m-%dT%H:%M:%S+00:00')
            if not begin:
                print("end @ %s had no beginning?", end)
                continue
            runtime = end - begin
            # NOTE(ianw): try to get what would have been the HEAD at
            # the time the run started.  "--first-parent" I hope means
            # that we show merge commits of when the change actually
            # was in the tree, not when it was originally proposed.
            git_head_commit = os.popen('git -C /opt/system-config/ rev-list --first-parent -1 --before="%s" master' % begin).read().strip()
            git_head = os.popen('git -C /opt/system-config log --abbrev-commit --pretty=oneline --max-count=1 %s' % git_head_commit).read().strip()
            print("%s - %s - %s" % (runtime, begin, git_head))
            begin = None

if begin:
    print("Incomplete run started @ %s" % begin)
