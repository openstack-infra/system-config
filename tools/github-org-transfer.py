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
import sys


GITHUB_API = "https://api.github.com"
GITHUB_USERNAME = os.environ.get("GITHUB_USERNAME", None)
GITHUB_PASSWORD = os.environ.get("GITHUB_PASSWORD", None)


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("src_repo", help="Source org/repo (ex: openstack/ara)")
    parser.add_argument("dst_repo", help="Destination org/repo (ex: stackforge/ara)")
    parser.add_argument("--dry-run", action="store_true",
        help="Check repositories and privileges but don't intiate any transfers."
    )
    args = parser.parse_args()
    return args


def is_organization_admin(session, repository):
    """
    Returns true if the current user has admin privileges for the repository's
    organization.
    """
    org = repository.split("/")[0]
    memberships = session.get("%s/user/memberships/orgs/%s" % (GITHUB_API, org))
    if memberships.status_code == 404:
        return False
    elif memberships.status_code != 200:
        raise Exception("Could not retrieve organization memberships: %s" % json.dumps(memberships.json(), indent=2))

    role = memberships.json()["role"]
    if role == "admin":
        return True
    return False


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

    # Ensure we have sufficient privileges to initiate the transfer
    for repository in [args.src_repo, args.dst_repo]:
        if not is_organization_admin(session, repository):
            raise Exception("Insufficient privileges for %s or it is a personal namespace" % repository)

    # Get source repository
    src_repo = session.get("%s/repos/%s" % (GITHUB_API, args.src_repo))
    # The source repository should exist. Raise an exception if it doesn't.
    src_repo.raise_for_status()
    src_repo = src_repo.json()

    # Check if the provided source repo name matches the GitHub repo name.
    # This is important because GitHub will have a different "full_name" if a
    # repo has been moved in the past. For example, if openstack/ara had been
    # moved to stackforge/ara in the past, querying openstack/ara would yield
    # the full_name stackforge/ara.
    if args.src_repo != src_repo["full_name"]:
        if src_repo["full_name"] == args.dst_repo:
            print("Nothing to do: repository has already been moved.")
            sys.exit(0)
        else:
            raise Exception("Source repository exists but as %s" % src_repo["full_name"])

    # Get destination repository
    dst_repo = session.get("%s/repos/%s" % (GITHUB_API, args.dst_repo))
    # The destination repository shouldn't exist. If it does, try to be helpful about it.
    if dst_repo.status_code == 200:
        dst_repo = dst_repo.json()
        if dst_repo["full_name"] == args.dst_repo:
            print("Nothing to do: repository has already been moved.")
            sys.exit(0)
        else:
            raise Exception("Destination repository exists but as %s" % dst_repo["full_name"])

    # Initiate transfer request
    payload = {
        "new_owner": args.dst_repo.split('/')[0]
    }

    if not args.dry_run:
        data = session.post("%s/%s/transfer" % (GITHUB_API, args.src_repo), data=json.dumps(payload))
        if data.status_code != 202:
            raise Exception("Failed to request transfer: %s" % json.dumps(data.json(), indent=2))
        print("Sent transfer request for %s to %s." % (args.src_repo, args.dst_repo))
    else:
        print("Not requesting transfer (dry-run enabled)")

if __name__ == "__main__":
    main()
