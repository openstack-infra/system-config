#!/usr/bin/env python
# Copyright 2019 Red Hat
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
#

import argparse
import requests
import json
import os


GITHUB_API = "https://api.github.com/repos"
GITHUB_USERNAME = os.environ.get("GITHUB_USERNAME", None)
GITHUB_PASSWORD = os.environ.get("GITHUB_PASSWORD", None)


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("src_repo", help="Source repository (ex: openstack/ara)")
    parser.add_argument("dst_repo", help="Where the source repository should be moved to (ex: stackforge/ara)")
    args = parser.parse_args()
    return args


def main():
    args = get_args()
    if GITHUB_USERNAME is None or GITHUB_PASSWORD is None:
        raise Exception("Environment variables GITHUB_USERNAME and GITHUB_PASSWORD must be set.")

    session = requests.Session()
    session.auth = (GITHUB_USERNAME, GITHUB_PASSWORD)
    session.headers.update({
        "Content-Type": "application/json",
        "Accept": "application/vnd.github.nightshade-preview+json"
    })

    # Get and sanity check the specified source and destination repos
    src_repo = session.get("%s/%s" % (GITHUB_API, args.src_repo)).json()
    if "full_name" in src_repo and args.src_repo == src_repo["full_name"]:
        print("Retrieved source repository successfully: %s" % args.src_repo)
    else:
        raise Exception("Unable to retrieve source repository or it is incorrect: %s" % args.src_repo)

    dst_repo = session.get("%s/%s" % (GITHUB_API, args.dst_repo)).json()
    if "message" in dst_repo and dst_repo["message"] == "Not Found":
        print("Destination repository (expectedly) does not exist yet: %s" % args.dst_repo)
    elif "full_name" in dst_repo and dst_repo["full_name"] != args.dst_repo:
        raise Exception("%s already exists and GitHub says it matches %s" % (args.dst_repo, dst_repo["full_name"]))
    else:
        raise Exception("Destination repository already exists or it is incorrect.")

    # Initiate transfer request
    payload = {
        "new_owner": args.dst_repo.split('/')[0]
    }
    data = session.post("%s/%s/transfer" % (GITHUB_API, args.src_repo), data=json.dumps(payload))
    if data.status_code != 202:
        raise Exception("Failed to request transfer, received http %s" % data.status_code)
    print("Sent transfer request for %s to %s." % (args.src_repo, args.dst_repo))

if __name__ == "__main__":
    main()

