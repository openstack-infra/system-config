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
#     $ virtualenv venv
#     [...]
#     $ ./venv/bin/pip install pyyaml requests
#     [...]
#     $ ./venv/bin/python tools/owners.py -a 2015-10-15 -i 11131 -o owners
#     No username on command line or in config, guessing "fungi"
#     No password provided in config, please enter:
#     MISSING: ansible-build-image
#     MERGING DUPLICATE ACCOUNT: 8074 into 2467
#     [...blah, blah, blah...wait for completion...]
#     $ ./venv/bin/python
#     >>> import yaml
#     >>>
#     >>> o = yaml.load(open('owners/_all_owners.yaml'))
#     >>> for c in range(5):
#     ...     print('Owners of at least %s changes: %s' % (
#     ...         c+1,
#     ...         len({k: v for k, v in o.iteritems() if v['count'] > c})))
#     ...
#     Owners of at least 1 changes: 1706
#     Owners of at least 2 changes: 1183
#     Owners of at least 3 changes: 951
#     Owners of at least 4 changes: 824
#     Owners of at least 5 changes: 734


from __future__ import print_function
import argparse
import csv
import datetime
import getpass
import json
import os
import string
import sys

import requests
import yaml


def dumper(data, stream):
    """Convenience wrapper to consistently set YAML formatting"""
    return yaml.safe_dump(data, allow_unicode=True, default_flow_style=False,
                          encoding='utf-8', stream=stream)


def normalize_email(email):
    """Lower-case the domain part of E-mail addresses to better spot
    duplicate entries, since the domain part is case-insensitive
    courtesy of DNS while the local part is not necessarily"""
    local, domain = email.split('@')
    domain = domain.lower()
    return '%s@%s' % (local, domain)


def normalize_project(project):
    """Replace spaces and hyphens with underscores in project teams
    and then lower-case them, for more convenient filenames"""
    return project.translate(string.maketrans(' -', '__')).lower()


def date_merged(change, after=None, before=None):
    """Determine the date and time a specific change merged"""

    # Until https://review.openstack.org/277538 is live, the merge
    # date is inferred from the last comment with no author field
    id_jenkins = 3
    date = None
    for message in reversed(change['messages']):
        if (('author' not in message) or (
                message['author']['_account_id'] == id_jenkins and
                message['message'] == 'Change has been successfully '
                'merged into the git repository.')):
            date = message['date']
            break

    # These should only be changes where submit was called outside the CI
    if not date:
        for message in reversed(change['messages']):
            if (message['message'] == 'Change has been successfully merged '
                    'into the git repository.'):
                date = message['date']
                break

    # Something's terribly wrong with any changes matching this now
    if not date:
        print(
            'SKIPPING DATELESS MERGE: change %s for account %s'
            % (change['_number'], change['owner']['_account_id']),
            file=sys.stderr)

    # Strip superfluous subsecond values as Gerrit always just
    # reports .000000000 for them anyway
    if date:
        date = date.split('.')[0]

    # Pass back an invalid result if it falls after the requested
    # cutoff
    if before and date >= before:
        return None

    # Sanity check for completeness, but since "after" is also used
    # in the Gerrit query this shouldn't ever actually be reached
    if after and date < after:
        return None

    return date


def query_gerrit(query, auth=None):
    """A requests wrapper to querying the Gerrit REST API"""
    # TODO(fungi): this could be switched to call pygerrit instead

    # The base URL to Gerrit, for accessing both GitWeb and the REST
    # API
    GERRIT_API_URL = 'https://review.openstack.org/'

    # Use the authenticated endpoint if an auth object is passed
    if auth:
        query = 'a/' + query

    # Retry http/https queries
    retry = requests.Session()
    retry.mount("http://", requests.adapters.HTTPAdapter(max_retries=3))
    retry.mount("https://", requests.adapters.HTTPAdapter(max_retries=3))
    raw = retry.get(GERRIT_API_URL + query, auth=auth,
                    headers={'Accept': 'application/json'})

    # Trap decoding failures and provide more detailed errors
    try:
        decoded = json.loads(raw.text[4:])
    except:
        print('\nrequest returned %s error to query:\n\n    %s\n'
              '\nwith detail:\n\n    %s\n' % (raw, query, raw.text),
              file=sys.stderr)
        raise
    return decoded


def main():
    """The giant pile of spaghetti which does everything else"""

    # Record the start time for use later
    start = datetime.datetime.utcnow()

    # TODO(fungi): this could be trivially extracted to a separate
    # function
    parser = argparse.ArgumentParser(description="When run using OpenStack's "
            "Gerrit server, this builds YAML representations of aggregate "
            "change owner details and change counts for each governance "
            "project-team, as well as a combined set for all teams. Before "
            "and after dates/times should be supplied in formats Gerrit "
            "accepts: https://review.openstack.org/Documentation/"
            "user-search.html#search-operators")
    parser.add_argument("-a", "--after", help="Start date for matching merges")
    parser.add_argument("-b", "--before", help="End date for matching merges")
    parser.add_argument("-c", "--config", help="Path to script configuration")
    parser.add_argument("-i", "--ignore", help="Account Id numbers to skip",
                        action='append')
    parser.add_argument("-o", "--outdir", help="Create an output directory")
    parser.add_argument("-r", "--ref", help="Specify a Governance refname")
    parser.add_argument("-s", "--sieve", help="Add Gerrit query parameters")
    parser.add_argument("-u", "--username", help="Your Gerrit username")
    options = parser.parse_args()

    # If we're supplied a configuration file, use it
    if options.config:
        config = yaml.safe_load(open(options.config))
    # Otherwise, use nothing
    else:
        config = {}

    # Start of the match timeframe for change merges
    if options.after:
        after = options.after
    elif 'after' in config:
        after = config['after']
    else:
        after = None

    # End of the match timeframe for change merges
    if options.before:
        before = options.before
    elif 'before' in config:
        before = config['before']
    else:
        before = None

    # Owner Ids for whom to ignore changes
    if options.ignore:
        ignore = [int(i) for i in options.ignore]
    elif 'ignore' in config:
        ignore = config['ignore']
    else:
        ignore = []

    # Output file directory
    if options.outdir:
        outdir = options.outdir
    elif 'outdir' in config:
        outdir = config['outdir']
    else:
        outdir = '.'
    if not os.path.isdir(outdir):
        os.makedirs(outdir)

    # Governance Git repository ref object for reference lists
    if options.ref:
        ref = options.ref
    elif 'ref' in config:
        ref = config['ref']
    else:
        ref = 'refs/heads/master'

    # Gerrit change query additions
    if options.sieve:
        sieve = options.sieve
    elif 'sieve' in config:
        sieve = config['sieve']
    else:
        sieve = None

    # The Gerrit username is taken from the CLI, then config, then
    # calling environment
    if options.username:
        username = options.username
    elif 'username' in config:
        username = config['username']
    else:
        username = os.environ['USER']
        print('No username on command line or in config, guessing "%s"'
              % username, file=sys.stderr)

    # The Gerrit HTTP password is taken from the config, then an
    # interactive prompt
    if 'password' in config:
        password = config['password']
    else:
        password = getpass.getpass(
            'No password provided in config, please enter: ')

    # Set up Gerrit API authentication, needed for the emails method
    GERRIT_AUTH = requests.auth.HTTPDigestAuth(username, password)

    # Path to the governance projects list, needs a Git refname as a
    # parameter
    PROJECTS_LIST = ('https://review.openstack.org/'
                     'gitweb?p=openstack/governance.git;a=blob_plain;'
                     'f=reference/projects.yaml;hb=%s')

    # The query identifying relevant changes
    match = 'status:merged'
    if after:
        match = '%s+after:"%s"' % (match, after)
    if sieve:
        match = '%s+%s' % (match, sieve)

    # The set of projects from the governance repo
    # TODO(fungi): make this a configurable option so that you can
    # for example supply a custom project list for running elections
    # in unofficial teams
    gov_projects = yaml.safe_load(requests.get(PROJECTS_LIST % ref).text)

    # A mapping of short (no prefix) to full repo names existing in
    # Gerrit, used to handle repos which have a different namespace
    # in governance during transitions and also to filter out repos
    # listed in governance which don't actually exist
    ger_repos = dict(
        [(x.split('/')[-1], x) for x in query_gerrit('projects/')])

    # This will be populated with change owners mapped to the
    # project-teams maintaining their respective Git repositories
    projects = {}

    # This will be populated with all change owners and their
    # account details
    owners = {}

    # This will be populated with discovered duplicate owners
    duplicates = {}

    # This will be populated with all individual E-mail addresses of
    # change owners, to facilitate finding and merging duplicate
    # accounts
    all_emails = {}

    # Iterate over all governance project-teams only at filename
    # generation time
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
                    print('MISSING: %s' % repo, file=sys.stderr)
                else:
                    # Query for an arbitrary change set and get
                    # detailed account information about the most
                    # recent patchset, paginating at 100 changes
                    # TODO(fungi): once Gerrit issue 3579 is fixed,
                    # we can drop the &o=MESSAGES to make this much
                    # more bandwidth efficient
                    offset = 0
                    changes = []
                    while offset >= 0:
                        changes += query_gerrit(
                            'changes/?q=project:%s+%s&n=100&start=%s'
                            '&o=CURRENT_COMMIT&o=CURRENT_REVISION'
                            '&o=DETAILED_ACCOUNTS&o=MESSAGES'
                            % (ger_repos[repo], match, offset))
                        if changes and changes[-1].get('_more_changes', False):
                            offset += 100
                        else:
                            offset = -1

                    # Iterate over each matched change in the repo
                    for change in changes:
                        # Get the merge date and skip if it's
                        # outside any requested date range
                        merged = date_merged(change, after, before)
                        if not merged:
                            continue

                        # We index owners by their unique Gerrit
                        # account Id numbers
                        owner = change['owner']['_account_id']

                        # If this owner is in the blacklist of Ids
                        # to skip, then move on to the next change
                        if owner in ignore:
                            continue

                        # Seen this owner already?
                        new_owner = owner
                        new = False
                        if owner in duplicates:
                            owner = duplicates[owner]
                        elif owner not in owners:
                            new = True

                        # For new additions, initialize this as
                        # their first and record specific account
                        # details
                        if new:
                            # Get the set of all E-mail addresses
                            # Gerrit knows for this owner's account
                            # (currently requires modifyAccount
                            # permission until we're running
                            # https://review.openstack.org/267927 in
                            # production)
                            emails = query_gerrit(
                                'accounts/%s/emails'
                                % change['owner']['_account_id'],
                                auth=GERRIT_AUTH)

                            # Find duplicate addresses and merge
                            # accounts when that happens
                            for email in emails:
                                address = normalize_email(email['email'])
                                if address in all_emails:
                                    owner = all_emails[address]
                                    duplicates[new_owner] = owner
                                    print(
                                        'MERGING DUPLICATE ACCOUNT: %s into %s'
                                        % (new_owner, owner), file=sys.stderr)
                                    break

                        # For newly found non-duplicate owners,
                        # initialize the global change count,
                        # newest/oldest merged dates, and an empty
                        # list where extra E-mail addresses can be
                        # added; also track their full name and
                        # Gerrit username
                        if new and owner == new_owner:
                            # TODO(fungi): this is a prime candidate
                            # to become a struct, or maybe a class
                            owners[owner] = {
                                'count': 1,
                                'extra': [],
                                'name': change['owner']['name'],
                                'newest': merged,
                                'oldest': merged,
                                'username': change['owner']['username'],
                            }

                        # If we've seen this owner on another change
                        # in any repo then just iterate their global
                        # change counter and update newest/oldest
                        # dates
                        else:
                            owners[owner]['count'] += 1
                            if merged > owners[owner]['newest']:
                                owners[owner]['newest'] = merged
                            elif merged < owners[owner]['oldest']:
                                owners[owner]['oldest'] = merged

                        # We only want to add addresses if this is a
                        # new owner or a new duplicate
                        if new:
                            # Iterate over each E-mail address
                            for email in emails:
                                # Normalize the address before
                                # performing any matching since
                                # Gerrit doesn't do a great job of
                                # this on its own
                                address = normalize_email(email['email'])

                                # Track this in the full list of all
                                # known E-mail addresses
                                all_emails[address] = owner

                                # Whether Gerrit considers this the
                                # preferred E-mail address
                                preferred = email.get('preferred', False)

                                # Store the preferred E-mail address
                                # under its own key since it has a
                                # special status, but only if this
                                # is not a duplicate account
                                if preferred and owner == new_owner:
                                    owners[owner]['preferred'] = address

                                    # If this was already added to
                                    # the extras list due to an
                                    # additional pre-normalized
                                    # copy, remove it there
                                    if address in owners[owner]['extra']:
                                        owners[owner]['extra'].remove(address)

                                # Store a list of non-preferred
                                # addresses, deduplicating them in
                                # case they match post-normalization
                                # and treating duplicate preferred
                                # addresses as # non-preferred
                                else:
                                    if ((address not in owners[owner]['extra'])
                                            and (address != owners[owner].get(
                                                'preferred', ''))):
                                        owners[owner]['extra'].append(address)

                        # If we've seen this owner on another change
                        # in a repo under this project-team then
                        # just iterate their team change counter and
                        # update newest/oldest dates
                        if owner in projects[project]:
                            projects[project][owner]['count'] += 1
                            if merged > projects[project][owner]['newest']:
                                projects[project][owner]['newest'] = merged
                            elif merged < projects[project][owner]['oldest']:
                                projects[project][owner]['oldest'] = merged

                        # ...otherwise initialize this as their
                        # first
                        else:
                            # TODO(fungi): another potential struct
                            projects[project][owner] = {
                                'count': 1,
                                'newest': merged,
                                'oldest': merged,
                            }

    # The negative counter will be used as a makeshift account Id
    # for non-code contributors; those with owned changes use their
    # Gerrit account Id instead
    counter = 1

    # Use the before time as the only contribution time for non-code
    # contributors, falling back on the script start time if before
    # was not specified
    if before:
        if len(before) == 10:
            stamp = before + ' 00:00:00'
        else:
            stamp = before
    else:
        stamp = start.isoformat(sep=' ').split('.')[0]

    # Iterate over all extra-atcs entries
    for project in gov_projects:
        for extra_atc in gov_projects[project].get('extra-atcs', []):
            name = extra_atc['name']
            email = extra_atc['email']
            address = normalize_email(email)
            if address in all_emails:
                owner = all_emails[address]
            else:
                owner = -counter
                all_emails[address] = owner
                owners[owner] = {
                    'count': -1,
                    'extra': [],
                    'name': name,
                    'newest': stamp,
                    'oldest': stamp,
                    'preferred': address,
                    'username': '_non_code_contributor',
                }
            if owner not in projects[project]:
                projects[project][owner] = {
                    'count': -1,
                    'newest': stamp,
                    'oldest': stamp,
                }
            counter += 1

    # This will hold an address list for TC electorate rolls
    electorate = []

    # A table of owners for summit invites
    invites = []

    # A fresh pass through the owners to build some other datasets
    for owner in owners:
        # Sort extra E-mail address lists for ease of comparison
        owners[owner]['extra'].sort()

        # Build the data used for an invite
        invite = []
        invite.append(owners[owner]['username'])
        invite.append(owners[owner]['name'].encode('utf-8'))
        invite.append(owners[owner]['preferred'])
        invite += owners[owner]['extra']
        invites.append(invite)

        # Append preferred addresses to the TC electorate
        electorate.append(owners[owner]['preferred'] + '\n')

    # Write out a YAML file covering all change owners
    fd = open(os.path.join(outdir, '_all_owners.yaml'), 'w')
    dumper(owners, stream=fd)
    fd.close()

    # Write out a YAML file covering tracked duplicate accounts
    fd = open(os.path.join(outdir, '_duplicate_owners.yaml'), 'w')
    dumper(duplicates, stream=fd)
    fd.close()

    # Write out a team-specific electoral roll for CIVS
    fd = open(os.path.join(outdir, '_electorate.txt'), 'w')
    fd.writelines(electorate)
    fd.close()

    # Write out a CSV file appropriate for the invite2summit tool
    fd = open(os.path.join(outdir, '_invites.csv'), 'w')
    csv.writer(fd).writerows(invites)
    fd.close()

    # Make another pass through the projects so they can be dumped
    # to our output files
    for project in projects:

        # This will hold team-specific info for writing
        output = {}

        # This will hold an address list for PTL electoral rolls
        electorate = []

        # Use a normalized project name for output file names
        normalized_project = normalize_project(project)

        # Iterate over each change owner for the current team
        for owner in projects[project]:
            # Copy the global owner details into our output since
            # we're going to modify some
            output[owner] = dict(owners[owner])

            # Replace the owner change count and newest/oldest
            # merged dates with the team-specific value rather than
            # using the count from the global set
            for field in ('count', 'newest', 'oldest'):
                output[owner][field] = projects[project][owner][field]

            # Append preferred addresses to the PTL electoral rolls
            electorate.append(owners[owner]['preferred'] + '\n')

        # Write out a team-specific YAML file
        fd = open(os.path.join(outdir, '%s.yaml' % normalized_project), 'w')
        dumper(output, stream=fd)
        fd.close()

        # Write out a team-specific electoral roll for CIVS
        fd = open(os.path.join(outdir, '%s.txt' % normalized_project), 'w')
        fd.writelines(electorate)
        fd.close()

main()
