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


"""
Git Symbolic Head Reference Manager

This script manages git symbolic references to alternate heads within
any arbitrary number of git repositories described within the YAML file
provided as its only command line argument. Symbolic references will be
created, updated or deleted to match those listed for the particular
repository. If a repository named "defaults" is included within the file
it will not be treated as an actual repository, and can therefore be
used for a merge key.

No repository will be modified unless explicitly listed within the file.
Special care is taken to only act upon symbolic references within
refs/heads/ (not direct head references for real branches), and to
otherwise avoid creating detached or recursive symbolic references.

Usage::

  symbolic_heads.py symbolic_heads.yaml

Example::

  defaults: &defaults
    path: /home/gerrit2/review_site/git
    symbols:
      xyzzy: master
  test.git:
    <<: *defaults
    symbols:
      plover: br1
      plugh: br2
      xyzzy: master
  test2.git:
    <<: *defaults
"""


import os, sys
import git # debian package python-git
import yaml #debian package python-yaml

try:
    # The YAML file should be passed as the first (only) CLI parameter...
    proposals = yaml.load(open(sys.argv[1]))
except IndexError:
    # ...so if it wasn't, fail with a user-friendly message.
    sys.stderr.write('ERROR: Must specify a YAML file to load.\n')
    sys.exit(1)

# The defaults metaproposal exists only for the benefit of the YAML parser.
del(proposals['defaults'])

# This will contain a representation of the existing branches and symbolic
# head references corresponding to those described in the YAML file.
existing = {}
for proposal in proposals:
    # Compose the proposal name and base path and try to load it, failing
    # with a user-friendly error if it doesn't exist or is malformed.
    path = os.path.join(proposals[proposal]['path'], proposal)
    try:
        repo = git.Repo(path)
    except git.exc.NoSuchPathError or git.exc.InvalidGitRepositoryError:
        sys.stderr.write('ERROR: There is no valid git repository at\n'
                         '    %s\n'%path)
        sys.exit(1)
    # Track base repos, branches and symbolic head references separately.
    existing[proposal] = {'repo': repo, 'branches': {}, 'symbols': {}}
    for head in repo.heads:
        if hasattr(head, 'reference'):
            # A Head object only has a reference attribute if it's symbolic...
            existing[proposal]['symbols'][str(head)] = head
        else:
            # ...otherwise it's a branch or similar direct commit reference.
            existing[proposal]['branches'][str(head)] = head
    # Now make sure the proposed symbolic reference changes are sane.
    for symbol,reference in proposals[proposal]['symbols'].items():
        if reference not in existing[proposal]['branches']:
	    # We don't want to point a symbol at anything besides an actual
	    # commit reference.
            sys.stderr.write('ERROR: There is no existing branch at\n'
                             '    %s/refs/heads/%s\n'%(proposal, reference))
            sys.exit(1)
        if symbol in existing[proposal]['branches']:
	    # We don't want to blow away existing commit references either.
            sys.stderr.write('ERROR: Refusing to replace existing branch with\n'
                             '    %s/refs/heads/%s\n'%(proposal, symbol))
            sys.exit(1)

# If we got this far, it should be safe to apply our changes.
for proposal in proposals:
    project = existing[proposal]
    for symbol,reference in proposals[proposal]['symbols'].items():
        if symbol in project['symbols']:
            oldsym = project['symbols'][symbol]
            if str(oldsym.reference) != reference:
                # Only bother changing the symbolic reference if it doesn't
                # already match.
                message = 'updated from %s to %s by %s' % (oldsym.reference,
                                                           reference,
                                                           sys.argv[0])
                oldsym.set_reference(project['branches'][reference],
                                     logmsg=message)
                print('%s %s: %s' % (proposal, symbol, message))
        else:
            # Create a new symbolic reference if necessary.
            message = 'created as a symbolic ref for %s by %s' % (reference,
                                                                  sys.argv[0])
            newsym = project['repo'].create_head(symbol, logmsg=message)
            newsym.set_reference(project['branches'][reference])
            print('%s %s: %s' % (proposal, symbol, message))
    for symbol in project['symbols']:
        if str(symbol) not in proposals[proposal]['symbols']:
            # Get rid of any stale symbolic references.
            print('%s %s: removed as a symbolic ref to %s by %s' % (proposal,
                symbol, project['symbols'][symbol].reference, sys.argv[0]))
            git.SymbolicReference.delete(project['repo'],
                                              'refs/heads/%s'%symbol)
