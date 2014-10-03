# Copyright 2013 OpenStack Foundation
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

# Most of this code originated in sphinx.domains.python and
# sphinx.ext.autodoc and has been only slightly adapted for use in
# subclasses here.

# Thanks to Doug Hellman for:
# http://doughellmann.com/2010/05/defining-custom-roles-in-sphinx.html

from docutils import nodes


def file_role(name, rawtext, text, lineno, inliner,
              options={}, content=[]):
    """Link a local path to a cgit file view.

    Returns 2 part tuple containing list of nodes to insert into the
    document and a list of system messages.  Both are allowed to be
    empty.

    :param name: The role name used in the document.
    :param rawtext: The entire markup snippet, with role.
    :param text: The text marked with the role.
    :param lineno: The line number where rawtext appears in the input.
    :param inliner: The inliner instance that called us.
    :param options: Directive options for customization.
    :param content: The directive content for customization.
    """

    ref = ('https://git.openstack.org/cgit/openstack-infra/'
           'system-config/tree/%s' % text)
    linktext = 'system-config: %s' % text
    node = nodes.reference(rawtext, linktext, refuri=ref, **options)
    return [node], []


def config_role(name, rawtext, text, lineno, inliner,
                options={}, content=[]):
    """Link a local path to a cgit file view.

    Returns 2 part tuple containing list of nodes to insert into the
    document and a list of system messages.  Both are allowed to be
    empty.

    :param name: The role name used in the document.
    :param rawtext: The entire markup snippet, with role.
    :param text: The text marked with the role.
    :param lineno: The line number where rawtext appears in the input.
    :param inliner: The inliner instance that called us.
    :param options: Directive options for customization.
    :param content: The directive content for customization.
    """

    ref = ('https://git.openstack.org/cgit/openstack-infra/'
           'project-config/tree/%s' % text)
    linktext = 'project-config: %s' % text
    node = nodes.reference(rawtext, linktext, refuri=ref, **options)
    return [node], []


def setup(app):
    """Install the plugin.

    :param app: Sphinx application context.
    """
    app.add_role('file', file_role)
    app.add_role('config', config_role)
    return
