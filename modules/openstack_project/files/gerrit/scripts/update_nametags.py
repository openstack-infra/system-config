#!/usr/bin/env python
# Copyright 2013 Hewlett-Packard Development Company, L.P.
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

# This is designed to be called by a Gerrit ref-updated hook. It consumes a
# YAML description of tag->branch mappings from a file in a specified
# meta-branch and updates one or more lightweight tags to constantly track the
# tip of the branch corresponding to the updated reference.


import argparse, os, sys
import git  # debian package python-git
import yaml # debian package python-yaml


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('hook')
    parser.add_argument('--description', default=None)
    parser.add_argument('--oldrev', default=None)      # unused
    parser.add_argument('--newrev', default=None)      # unused
    parser.add_argument('--refname', default=None)
    parser.add_argument('--project', default=None)
    parser.add_argument('--submitter', default=None)   # unused
    args = parser.parse_args()

    # Sanity.
    assert args.hook == "ref-updated"

    # The relevant git base directory is passed from Gerrit in the calling
    # environment.
    repo = git.Repo(os.environ['GIT_DIR'])

    # The --description should be a colon-separated pair of git meta-branch
    # reference name and relative path to the YAML file containing a
    # tag->branch mapping.
    mname,fname = args.description.split(':', 1)
    try:
        # Dig the YAML file contents out of the tip of the meta-branch.
        tags = yaml.load(repo.refs[mname].commit.tree[fname].data_stream)
    except LookupError:
        # We're not configured to act on this project, so stop wasting time.
        sys.exit(0)

    if args.refname == 'refs/meta/%s'%mname:
        # This was a change to the meta-branch, so reapply all tags now in case
        # any were changed.
        branches = [x.name for x in repo.branches]
    else:
        # Only update tags slated for the same branch into which we just
        # merged.
        branches = [args.refname]

    for tag,branch in tags.items():
        if branch in branches:
            repo.create_tag(tag, repo.branches[branch], force=True)


if __name__ == '__main__':
    main()
