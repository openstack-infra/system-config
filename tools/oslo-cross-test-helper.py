#!/usr/bin/python
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
"""Check the configuration of cross-tests for Oslo libraries against
the projects known to depend on them and report if anything is amiss.

This script assumes that you have a copy of *all* of the
openstack-related repositories checked out in a directory structure
that reflects their layout in gerrit (i.e., 'openstack/oslo.config'
vs. just 'oslo.config'). It defaults to looking in '/opt/stack'.

"""

from __future__ import print_function

import argparse
import functools
import itertools
import glob
import os

from pip import req
import yaml

JJB_ROOT = 'modules/openstack_project/files/jenkins_job_builder/config'
ZUUL_ROOT = 'modules/openstack_project/files/zuul'
PROGRAMS_YAML = 'openstack/governance/reference/programs.yaml'


def _check(msg, f, verbose):
    """Perform a single check by calling f.
    """
    try:
        r = f()
    except Exception as e:
        print('%s ... ERROR: %s' % (msg, e))
    else:
        if not r or verbose:
            print('%s ... %s' %
                  (msg, 'OK' if r else 'FAIL'))


def _pass_through(pip):
    """Determine if we should ignore the line from the requirements file.
    """
    # Based openstack/requirements/update.py
    return (not pip or
            pip.startswith('#') or
            pip.startswith('http://tarballs.openstack.org/') or
            pip.startswith('-e') or
            pip.startswith('-f'))


def _parse_pip(pip):
    """Parse one entry in a requirements file.
    """
    # Based openstack/requirements/update.py
    install_require = req.InstallRequirement.from_line(pip)
    if install_require.editable:
        return pip
    elif install_require.url:
        return pip
    else:
        return install_require.req.key


def _read_requirements(filename):
    """Read a requirements file as passed to pip.
    """
    with open(filename, 'r') as f:
        return set([
            _parse_pip(l.strip())
            for l in f.readlines()
            if not _pass_through(l.strip())
        ])


def _find_users(repo_path, lib, verbose):
    """Find other projects that use the library.
    """
    # FIXME(dhellmann): Do we need to add the test requirements here?
    for reqbase in ['requirements.txt', 'requirements-py3.txt']:
        req_txt = os.path.join(repo_path, reqbase)
        if not os.path.exists(req_txt):
            continue
        reqs = _read_requirements(req_txt)
        user = os.path.basename(repo_path)
        if lib in reqs:
            if verbose:
                print('found %s in %s/%s' %
                      (lib, os.path.basename(repo_path), reqbase))
            yield user


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--repo-dir', '-r',
        default='/opt/stack',
        help='root directory where repositories are checked out (%(default)s)',
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        default=False,
        help='verbose output',
    )
    parser.add_argument(
        'lib',
        nargs='*',
        help='Oslo library name(s) to check',
    )
    args = parser.parse_args()

    check = functools.partial(_check, verbose=args.verbose)
    find_users = functools.partial(_find_users, verbose=args.verbose)

    projects_yaml_filename = os.path.join(JJB_ROOT, 'projects.yaml')
    print('Loading Projects JJB config from %s' % projects_yaml_filename)
    projects_yaml = yaml.load(open(projects_yaml_filename))
    projects = {
        p['project']['name']: p['project']
        for p in projects_yaml if 'project' in p
    }

    layout_yaml_filename = os.path.join(ZUUL_ROOT, 'layout.yaml')
    print('Loading Zuul layout config from %s' % layout_yaml_filename)
    layout_yaml = yaml.load(open(layout_yaml_filename))
    zuul_projects = {
        p['name']: p
        for p in layout_yaml['projects']
    }

    programs_yaml_filename = os.path.join(args.repo_dir, PROGRAMS_YAML)
    print('Loading governance programs list from %s' % programs_yaml_filename)
    programs_yaml = yaml.load(open(programs_yaml_filename))
    incubated_projects = set(
        itertools.chain(
            repo['repo'].partition('/')[-1]
            for pgm in programs_yaml.values()
            for repo in pgm.get('projects', [])
            if repo.get('incubated-since') and not repo.get('integrated-since')
        )
    )
    print('Incubated projects: %s' % sorted(incubated_projects))
    integrated_projects = set(
        itertools.chain(
            repo['repo'].partition('/')[-1]
            for pgm in programs_yaml.values()
            for repo in pgm.get('projects', [])
            if repo.get('integrated-since')
        )
    )
    print('Integrated projects: %s' % sorted(integrated_projects))

    if args.lib:
        oslo_libs = args.lib
    else:
        ignore = set([
            'openstack-dev/cookiecutter',  # not a lib
            'openstack-dev/hacking',  # not a lib
            'openstack-dev/oslo-cookiecutter',  # not a lib
            'openstack-dev/pbr',  # always used
            'openstack/oslo-incubator',  # not a lib
            'openstack/oslosphinx',  # not a production lib
            'openstack/oslo.rootwrap',  # not used in unit tests
            'openstack/oslotest',  # always used (add later?)
            'openstack/oslo.version',  # not used
        ])
        oslo_libs = [
            r['repo'].partition('/')[-1]
            for r in programs_yaml['Common Libraries']['projects']
            if (r['repo'] not in ignore
                and not r.get('integrated-since')
                and not r.get('incubated-since'))
        ]

    for lib in oslo_libs:
        if args.verbose:
            print(lib.upper())

        # Make sure the library has a project defined.
        check('%s in projects.yaml' % lib,
              lambda: lib in projects)

        # Look for jobs for the users of the library.
        repo_pattern = os.path.join(args.repo_dir, 'openstack', '*')
        for repo_path in glob.glob(repo_pattern):
            for user in find_users(repo_path, lib):
                if user in integrated_projects:
                    user_type = 'integrated'
                elif user in incubated_projects:
                    user_type = 'incubated'
                elif user in oslo_libs:
                    user_type = 'oslo'
                elif user.startswith('python-') and user.endswith('client'):
                    parent = user[len('python-'):-len('client')]
                    if parent in integrated_projects:
                        user_type = 'integrated client'
                    elif parent in incubated_projects:
                        user_type = 'incubated client'
                    else:
                        user_type = 'other client'
                else:
                    user_type = 'other'
                if args.verbose:
                    print('found %s project %s using %s' %
                          (user_type, user, lib))

                if user == 'oslo-incubator':
                    if args.verbose:
                        print('no cross-tests against the incubator')
                    continue

                if user_type in ('other', 'other client'):
                    if args.verbose:
                        print('...ignoring %s user' % user_type)
                    continue

                # The rest of the checks only apply to integrated
                # projects and other oslo libraries.
                if user_type not in ('oslo', 'integrated',
                                     'integrated client'):
                    continue

                # Make sure the consuming project is being tested
                # against master branches of any oslo libraries it
                # uses by having the appropriate project and layout
                # entries for 'test-with-oslo-master'.
                check(('test-with-oslo-master in job list for '
                       '%s project %s using %s in projects.yaml') %
                      (user_type, user, lib),
                      lambda: ('test-with-oslo-master'
                               in projects[user]['jobs']))

                user_templates = zuul_projects['openstack/' + user].get(
                    'template', [])
                check(('test-with-oslo-master in template list for '
                       '%s project %s in layout.yaml') %
                      (user_type, user),
                      lambda: any(t['name'] == 'test-with-oslo-master'
                                  for t in user_templates))

                # Make sure the settings for the consuming project
                # create jobs to be used to test changes to the
                # library being consumed.
                #
                # Some jobs are simple strings, but the ones we
                # want for uses-oslo-lib are a dictionary:
                #   - uses-oslo-lib:
                #       oslo-lib: stevedore
                check(
                    ('uses-oslo-lib for lib %s in jobs list '
                     'for %s project %s in projects.yaml') %
                    (lib, user_type, user),
                    lambda: any(
                        j.get('uses-oslo-lib', {}).get('oslo-lib') == lib
                        for j in projects[user]['jobs']
                        if isinstance(j, dict))
                )

                # Look for the jobs created by 'uses-oslo-lib' from
                # oslo.yaml to be configured to run for the library
                # that is being used.
                for pipeline in ['check', 'gate']:
                    lib_job_name = '%s-%s-dsvm-%s' % (pipeline, lib, user)
                    lib_jobs = zuul_projects['openstack/' + lib].get(
                        pipeline,
                        [])

                    # Make sure we are running the tests for the
                    # consuming project with master of the library.
                    check('%s configured for library %s in layout.yaml'
                          % (lib_job_name, lib),
                          lambda: lib_job_name in lib_jobs)

        if args.verbose:
            print()


if __name__ == '__main__':
    main()
