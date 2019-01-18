# Copyright (c) 2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM python:slim as fake-python

COPY python3-dev.control /tmp/python3-dev.control
WORKDIR /tmp
RUN apt-get update && apt-get install -y equivs
RUN equivs-build /tmp/python3-dev.control

FROM python:slim as python-builder

COPY --from=fake-python /tmp/python3-dev_4.0.0_all.deb /tmp/python3-dev_4.0.0_all.deb
COPY scripts/assemble /usr/local/bin/assemble
COPY scripts/get-extras-packages /usr/local/bin/get-extras-packages
COPY scripts/install-from-bindep /output/install-from-bindep
RUN dpkg -i /tmp/python3-dev_4.0.0_all.deb \
  && rm /tmp/python3-dev_4.0.0_all.deb \
  && pip install bindep

FROM python:slim as python-base

RUN apt-get update \
  && apt-get install -y dumb-init \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
