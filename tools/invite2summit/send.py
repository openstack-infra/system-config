# Summit passcode-sending application
#
# Copyright 2013 Thierry Carrez <thierry@openstack.org>
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import csv
import settings
import smtplib
import sys
import time
from string import Template


class ATC(object):
    def __init__(self, row):
        self.lpid = row[0]
        self.name = row[1]
        self.emails = row[2:]


if __name__ == '__main__':

    if len(sys.argv) != 3:
        print "Usage: %s atc.csv codes.csv" % sys.argv[0]
        sys.exit(1)

    atcfile = sys.argv[1]
    codesfile = sys.argv[2]

    committers = []
    with open(atcfile, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            committers.append(ATC(row))

    codes = []
    with open(codesfile, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            codes.append(row[0])

    for committer, code in zip(committers, codes):
        if settings.EMAIL_USE_SSL:
            session = smtplib.SMTP_SSL(
                settings.EMAIL_HOST, settings.EMAIL_PORT)
        else:
            session = smtplib.SMTP(settings.EMAIL_HOST, settings.EMAIL_PORT)
        if settings.EMAIL_USE_TLS:
            session.starttls()
        session.login(settings.EMAIL_USER, settings.EMAIL_PASSWORD)
        session.set_debuglevel(settings.EMAIL_DEBUGLEVEL)

        template = Template(settings.EMAIL_TEMPLATE)
        content = template.substitute(name=committer.name,
                                      code=code,
                                      signature=settings.EMAIL_SIGNATURE)
        msg = "From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s" % (
            settings.EMAIL_FROM, ','.join(committer.emails),
            settings.EMAIL_SUBJECT, content)

        session.sendmail(settings.EMAIL_FROM, committer.emails, msg)
        print "%s,ATC,%s" % (code, committer.name)
        session.quit()
        time.sleep(settings.EMAIL_PAUSE)
