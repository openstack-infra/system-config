#! /usr/bin/env python
# Copyright (C) 2012 OpenStack, LLC.
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

# Jenkins Job module for pep8 publishers
# No additional YAML needed

import xml.etree.ElementTree as XML

class publisher_pep8(object):
    def __init__(self, data):
        self.data = data

    def gen_xml(self, xml_parent):
        publishers = XML.SubElement(xml_parent, 'publishers')
        violations = XML.SubElement(publishers, 'hudson.plugins.violations.ViolationsPublisher')
        config = XML.SubElement(violations, 'config')
        suppressions = XML.SubElement(config, 'suppressions', {'class':'tree-set'})
        XML.SubElement(suppressions, 'no-comparator')
        configs = XML.SubElement(config, 'typeConfigs')
        XML.SubElement(configs, 'no-comparator')
        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'checkstyle'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'checkstyle'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'codenarc'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'codenarc'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'cpd'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'cpd'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'cpplint'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'cpplint'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'csslint'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'csslint'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'findbugs'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'findbugs'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'fxcop'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'fxcop'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'gendarme'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'gendarme'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'jcreport'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'jcreport'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'jslint'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'jslint'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'pep8'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'pep8'
        XML.SubElement(tconfig, 'min').text = '0'
        XML.SubElement(tconfig, 'max').text = '1'
        XML.SubElement(tconfig, 'unstable').text = '1'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern').text = '**/pep8.txt'

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'pmd'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'pmd'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'pylint'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'pylint'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'simian'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'simian'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        entry = XML.SubElement(configs, 'entry')
        XML.SubElement(entry, 'string').text = 'stylecop'
        tconfig = XML.SubElement(entry, 'hudson.plugins.violations.TypeConfig')
        XML.SubElement(tconfig, 'type').text = 'stylecop'
        XML.SubElement(tconfig, 'min').text = '10'
        XML.SubElement(tconfig, 'max').text = '999'
        XML.SubElement(tconfig, 'unstable').text = '999'
        XML.SubElement(tconfig, 'usePattern').text = 'false'
        XML.SubElement(tconfig, 'pattern')

        XML.SubElement(config, 'limit').text = '100'
        XML.SubElement(config, 'sourcePathPattern')
        XML.SubElement(config, 'fauxProjectPath')
        XML.SubElement(config, 'encoding').text = 'default'
