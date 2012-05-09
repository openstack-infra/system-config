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

# A basic API class to talk to a Jenkins Server

# TODO: lots of things, including delete:
# curl -X POST -v http://localhost:8080/job/blagoo/doDelete
# --- when found returns 302 ?! w/no content, when not found 404 with a bunch of html junk

import pycurl
from StringIO import StringIO

class JenkinsTalkerException(Exception): pass

class JenkinsTalker(object):
    def __init__(self, url, user, password):
        self.url = url
        self.user = user
        self.password = password

    def _post_xml(self, path, xml):
        curl = pycurl.Curl()
        response = StringIO()
        curl.setopt(pycurl.URL, self.url + path)
        curl.setopt(pycurl.USERPWD, self.user + ":" +  self.password)
        curl.setopt(pycurl.POST, 1)
        curl.setopt(pycurl.POSTFIELDS, xml)
        curl.setopt(pycurl.HTTPHEADER, [ "Content-Type: text/xml" ])
        curl.setopt(pycurl.POSTFIELDSIZE, len(xml))
        # should probably shove this response into a debug output somewhere
        curl.setopt(pycurl.WRITEFUNCTION, response.write)
        curl.perform()
        if curl.getinfo(pycurl.RESPONSE_CODE) not in [ 200 ]:
            raise JenkinsTalkerException('error posting XML')
        curl.close()

    def _get_request(self, path):
        curl = pycurl.Curl()
        response = StringIO()
        curl.setopt(pycurl.URL, self.url + path)
        curl.setopt(pycurl.USERPWD, self.user + ":" +  self.password)
        curl.setopt(pycurl.WRITEFUNCTION, response.write)
        curl.perform()
        if curl.getinfo(pycurl.RESPONSE_CODE) not in [ 200 ]:
            raise JenkinsTalkerException('error getting response')
        curl.close()
        return response.getvalue()

    def create_job(self, job_name, xml):
        path = 'createItem?name=' + job_name
        self._post_xml(path, xml)

    def update_job(self, job_name, xml):
        path = 'job/' + job_name + '/config.xml'
        self._post_xml(path, xml)

    def get_job_config(self, job_name):
        path = 'job/' + job_name + '/config.xml'
        return self._get_request(path)

    def is_job(self, job_name):
        try:
            self.get_job_config(job_name)
        except JenkinsTalkerException:
            return False
        return True

