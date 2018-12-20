# Copyright 2018 Red Hat, Inc.
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

FROM python:slim as build

RUN apt-get update && apt-get -y install \
    git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /src/jinja-init

RUN git clone https://github.com/ObjectifLibre/jinja-init /src/jinja-init
WORKDIR /src/jinja-init

RUN git checkout 8c13a44124a5a363519df787b1cd0abd1198b8df

FROM python:slim as jinja-init

RUN pip install jinja2

COPY --from=build /src/jinja-init/run.py /

ENTRYPOINT ["python", "/run.py"]
