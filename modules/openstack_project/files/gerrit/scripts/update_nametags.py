#!/usr/bin/env python
# Copyright 2012 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# This is designed to be called by a gerrit change-merged hook. It consumes a
# YAML description of project->tag->branch mappings, and updates a lightweight
# git tag to refer to the tip of the corresponding branch when a new change is
# merged.


import argparse, os
import git  # debian package python-git
import yaml # debian package python-yaml


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('hook')                        # unused
    parser.add_argument('--description', default=None)
    parser.add_argument('--change', default=None)      # unused
    parser.add_argument('--change-url', default=None)  # unused
    parser.add_argument('--project', default=None)
    parser.add_argument('--branch', default=None)
    parser.add_argument('--submitter', default=None)   # unused
    parser.add_argument('--commit', default=None)      # unused
    args = parser.parse_args()

    projects = yaml.load(open(args.description))

    # The "defaults" metaproject exists only for the benefit of the YAML
    # parser, so deleting it ensures we never apply its contents to an actual
    # project named "defaults".
    if 'defaults' in projects: del(projects['defaults'])

    try:
        project = projects[args.project]
    except KeyError:
        # We're not configured to act on this project, so stop wasting time.
        sys.exit(0)

    repo = git.Repo(os.environ['GIT_DIR'])
    for tag,branch in filter(lambda(t,b): b==args.branch, project.items()):
        # Create or update tags for the same branch into which we just merged.
        repo.create_tag(tag, repo.branches[branch], force=True)


if __name__ == '__main__':
    main()
