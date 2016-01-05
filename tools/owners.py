#!/usr/bin/env python

# Copyright (c) 2016 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an "AS
# IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Description: When run using OpenStack's Gerrit server, this builds
# YAML representations of aggregate change owner details and change
# counts for each governance project-team, as well as a combined set
# for all teams.

# Rationale: The OpenStack Technical Committee and Project Team Lead
# elections need electorate rolls taken from "Active Technical
# Contributors" to any repos under official project-teams over a
# particular timeframe. Similarly, the OpenStack Foundation gives
# summit registration discount codes to contributors meeting similar
# criteria. The Gerrit REST API provides access to all the data
# necessary to identify these individuals.

# Use: This needs your Gerrit username passed as the command-line
# parameter, found at https://review.openstack.org/#/settings/ when
# authenticated in the WebUI. It also prompts for an HTTP password
# which https://review.openstack.org/#/settings/http-password will
# allow you to generate. The results end up in files named for each
# official governance project-team (or "all") ending with a .yaml
# extension. At the time of writing, it takes approximately 21
# minutes to run on a well-connected machine with 70-80ms round-trip
# latency to review.openstack.org.

# Example:
#
#     $ virtualenv owners
#     [...]
#     $ ./owners/bin/pip install pyyaml requests
#     [...]
#     $ ./owners/bin/python tools/owners.py fungi
#     Password:
#     [wait for completion]
#     $ ./owners/bin/python
#     >>> import yaml
#     >>>
#     >>> o = yaml.load(open('all_owners.yaml'))
#     >>> for c in range(5):
#     ...     print('Owners of at least %s changes: %s' % (
#     ...         c+1,
#     ...         len({k: v for k, v in o.iteritems() if v['count'] > c})))
#     ...
#     Owners of at least 1 changes: 2056
#     Owners of at least 2 changes: 1463
#     Owners of at least 3 changes: 1202
#     Owners of at least 4 changes: 1037
#     Owners of at least 5 changes: 941


import getpass
import json
import string
import sys

import requests
import yaml


def normalize_email(email):
    if type(email) is unicode:
        email = email.encode('utf-8')
    local, domain = email.split('@')
    domain = domain.lower()
    return '%s@%s' % (local, domain)


# TODO(fungi): add a wrapper function for requests to provide better
# error handling and debugging output rather than always assuming
# the content will be valid JSON


def main():
    # The base URL to Gerrit, for accessing both GitWeb and the REST
    # API
    GERRIT_URL = 'https://review.openstack.org/'

    # Set up Gerrit API authentication, needed for the emails method
    # TODO(fungi): if we can allow viewAllAccounts for anonymous
    # users, then we can drop authentication entirely
    try:
        GERRIT_AUTH = requests.auth.HTTPDigestAuth(
            sys.argv[1], getpass.getpass())
    except IndexError:
        sys.stderr.write("Usage: %s USERNAME\n" % sys.argv[0])
        sys.exit(1)

    # GitWeb path under GERRIT_URL to find the governance projects
    # list, needs a Git refname as a parameter
    PROJECTS_FILE = ('gitweb?p=openstack/governance.git;a=blob_plain;'
                     'f=reference/projects.yaml;hb=%s')

    # TODO(fungi): add support for the governance extra-atcs file

    # Git refname to use in the governance repo for the
    # projects/extra-atcs lists
    # TODO(fungi): make a CLI option so we can pass in election tags
    REF_NAME = 'refs/heads/master'

    # Transformation to replace spaces and hyphens with underscores
    # when creating filenames for each project-team
    # TODO(fungi): this should be configurable
    FNTRANS = string.maketrans('__', ' -')

    # TODO: add command-line options for begin and end date/time

    # The query identifying relevant changes
    # TODO(fungi): this needs to be composed of the following...
    #   * status:merged
    #   * -age: inferred from a begin date, for efficiency
    #   * a placeholder for additional query options
    QUERY = 'status:merged+-age:"6 months"'

    # The set of projects from the governance repo
    # TODO(fungi): make this a configurable option so that you can
    # for example supply a custom project list for running elections
    # in unofficial teams
    gov_projects = yaml.safe_load(
        requests.get(GERRIT_URL + PROJECTS_FILE % REF_NAME).text)

    # A mapping of short (no prefix) to full repo names existing in
    # Gerrit, used to handle repos which have a different namespace
    # in governance during transitions and also to filter out repos
    # listed in governance which don't actually exist
    ger_repos = dict([(x.split('/')[-1], x) for x in json.loads(
        requests.get(GERRIT_URL + 'projects/?pp=0').text[4:])])

    # This will be populated with change owners mapped to the
    # project-teams maintaining their respective Git repositories
    projects = {}

    # This will be populated with all change owners and their
    # account details
    owners = {}

    # Iterate over all governance project-teams
    for project in gov_projects:
        # This will be populated with change owner Ids and counts
        projects[project] = {}

        # Governance project-teams have one or more deliverables
        for deliverable in gov_projects[project]['deliverables']:
            # Each deliverable can have multiple repos
            repos = gov_projects[project]['deliverables'][deliverable]['repos']

            # Operate on repo short-names (no namespace) to avoid
            # potential namespace mismatches between governance
            # and Gerrit
            for repo in [r.split('/')[-1] for r in repos]:
                # Only process repos which actually exist in Gerrit,
                # otherwise spew a warning if skipping
                if repo not in ger_repos:
                    sys.stderr.write('MISSING: %s\n' % repo)
                else:
                    # Query for an arbitrary change set and get
                    # detailed account information about the most
                    # recent patchset
                    changes = json.loads(requests.get(GERRIT_URL +
                        'changes/?q=project:%s+%s'
                        '&o=CURRENT_COMMIT&o=CURRENT_REVISION'
                        '&o=DETAILED_ACCOUNTS&pp=0'
                        % (ger_repos[repo], QUERY)).text[4:])

                    # Iterate over each matched change in the repo
                    # TODO(fungi): compare provided begin and end
                    # times against the last date of all authorless
                    # messages to filter those outside the desired
                    # timeframe until
                    # https://code.google.com/p/gerrit/issues/detail?id=3579
                    # is solved in a new Gerrit release
                    for change in changes:
                        # We index owners by their unique Gerrit
                        # account Id numbers
                        # TODO(fungi): add an Id blacklist so we can
                        # short-circuit and skip accounts like the
                        # proposal bot
                        owner = change['owner']['_account_id']

                        # If we've seen this owner on another change
                        # in a repo under this project-team then
                        # just iterate their team change counter...
                        if owner in projects[project]:
                            projects[project][owner] += 1

                        # ...otherwise initialize this as their
                        # first
                        # TODO(fungi): extend this to also track
                        # oldest and newest matches
                        else:
                            projects[project][owner] = 1

                        # If we've seen this owner on another change
                        # in any repo then just iterate their global
                        # change counter...
                        if owner in owners:
                            owners[owner]['count'] += 1

                        # ...otherwise initialize this as their
                        # first and record specific account details
                        else:
                            # In addition to the global change
                            # count, track their full name and
                            # Gerrit username; also initialize an
                            # empty list where extra E-mail
                            # addresses can be added
                            # TODO(fungi): extend this to also track
                            # oldest and newest matches
                            owners[owner] = {
                                'count': 1,
                                'extra': [],
                                'name': change['owner']['name'].encode(
                                    'utf-8'),
                                'username': change['owner']['username'].encode(
                                    'utf-8'),
                                }

                            # Get the set of all E-mail addresses
                            # Gerrit knows for this owner's account
                            # (requires viewAllAccounts permission)
                            emails = json.loads(requests.get(GERRIT_URL +
                                'a/accounts/%s/emails'
                                % change['owner']['_account_id'],
                                auth=GERRIT_AUTH).text[4:])

                            # Iterate over each E-mail address
                            # TODO(fungi): check each address
                            # against a table of all already seen
                            # addresses so we can spot and merge
                            # duplicate accounts
                            for email in emails:
                                # Normalize the address before
                                # performing any matching since
                                # Gerrit doesn't do a great job of
                                # this on its own
                                address = normalize_email(email['email'])

                                # Store the preferred E-mail address
                                # under its own key since it has a
                                # special status
                                if 'preferred' in email and email['preferred']:
                                    owners[owner]['preferred'] = address

                                # Store a list of non-preferred
                                # addresses, deduplicating them in
                                # case they match post-normalization
                                elif address not in owners[owner]['extra']:
                                    owners[owner]['extra'].append(address)

        # This will hold team-specific info for writing
        output = {}

        # Iterate over each change owner for the current team
        for owner in projects[project]:
            # Copy the global owner details into our output since
            # we're going to modify some
            output[owner] = dict(owners[owner])

            # Replace the owner change count with the team-specific
            # value rather than using the count from the global set
            output[owner]['count'] = projects[project][owner]

            # Write out a team-specific YAML file
            fd = open('%s.yaml' % project.translate(FNTRANS).lower(), 'w')
            fd.write(yaml.dump(output))
            fd.close()

    # Write out a YAML file covering all change owners
    fd = open('all_owners.yaml', 'w')
    fd.write(yaml.dump(owners))
    fd.close()

main()
