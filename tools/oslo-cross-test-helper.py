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
"""Check the configuration of cross-tests for an Oslo library
against the projects known to depend on it and report if anything
is amiss.

This script assumes that you have a copy of all of the
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

    oslo_yaml = yaml.load(open(os.path.join(JJB_ROOT, 'oslo.yaml')))
    oslo_jobs = {
        jg['job-group']['name']: jg['job-group']
        for jg in oslo_yaml if 'job-group' in jg
    }

    projects_yaml = yaml.load(open(os.path.join(JJB_ROOT, 'projects.yaml')))
    projects = {
        p['project']['name']: p['project']
        for p in projects_yaml if 'project' in p
    }

    layout_yaml = yaml.load(open(os.path.join(ZUUL_ROOT, 'layout.yaml')))
    zuul_projects = {
        p['name']: p
        for p in layout_yaml['projects']
    }

    programs_yaml = yaml.load(open(os.path.join(args.repo_dir, PROGRAMS_YAML)))
    incubated_projects = set(
        itertools.chain(
            repo.partition('/')[-1]
            for pgm in programs_yaml.values()
            for repo in pgm.get('projects', {}).get('incubated', [])
        )
    )
    integrated_projects = set(
        itertools.chain(
            repo.partition('/')[-1]
            for pgm in programs_yaml.values()
            for repo in pgm.get('projects', {}).get('integrated', [])
        )
    )

    if args.lib:
        oslo_libs = args.lib
    else:
        ignore = set([
            'openstack-dev/cookiecutter',
            'openstack-dev/hacking',
            'openstack-dev/oslo-cookiecutter',
            'openstack-dev/pbr',
            'openstack/oslo-incubator',
            'openstack/oslosphinx',
            'openstack/oslo.rootwrap',
            'openstack/oslo.test',
        ])
        oslo_libs = [
            r.partition('/')[-1]
            for r in programs_yaml['Common Libraries']['projects']['other']
            if r not in ignore
        ]

    for lib in oslo_libs:
        if args.verbose:
            print(lib.upper())

        # Make sure the job group for the library is defined.
        expected_job_group = '%s-cross-test' % lib
        check('%s in oslo.yaml' % expected_job_group,
              lambda: expected_job_group in oslo_jobs)
        check('%s has 2 jobs' % expected_job_group,
              lambda: len(oslo_jobs[expected_job_group]['jobs']) == 2)

        # Make sure the library has a project defined.
        check('%s in projects.yaml' % lib,
              lambda: lib in projects)
        check('%s *not* in jobs for %s' % (expected_job_group, lib),
              lambda: expected_job_group not in projects[lib]['jobs'])

        # Look for jobs for the users of the library.
        repo_pattern = os.path.join(args.repo_dir, 'openstack', '*')
        for repo_path in glob.glob(repo_pattern):
            for user in find_users(repo_path, lib):
                if user in integrated_projects:
                    user_type = 'integrated'
                elif user in incubated_projects:
                    user_type = 'incubated'
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
                        print('...ignoring')
                    continue

                check('%s configured for %s project %s in projects.yaml' %
                      (expected_job_group, user_type, user),
                      lambda: expected_job_group in projects[user]['jobs'])

                for pipeline in ['check', 'gate']:
                    lib_job_name = '%s-%s-dsvm-%s' % (pipeline, lib, user)
                    lib_jobs = zuul_projects['openstack/' + lib].get(pipeline, [])

                    # Test the library against the integrated project
                    # and its client.
                    if user_type in ('integrated client', 'integrated'):
                        check('%s configured for %s project %s in layout.yaml' %
                              (lib_job_name, user_type, lib),
                              lambda: lib_job_name in lib_jobs)

                    # Test incubated and integrated projects and their
                    # clients against the library.
                    user_jobs = zuul_projects['openstack/' + user].get(pipeline, [])
                    check('%s configured for %s project %s in layout.yaml' %
                          (lib_job_name, user_type, user),
                          lambda: lib_job_name in user_jobs)
        if args.verbose:
            print()


if __name__ == '__main__':
    main()
