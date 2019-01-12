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

FROM openjdk:8

RUN groupadd builder && \
  useradd builder --home-dir /usr/src --create-home -g builder
RUN \
  echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
  && curl -sL https://bazel.build/bazel-release.pub.gpg | apt-key add - \
  && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get update \
  && apt-get install -y bazel nodejs build-essential zip unzip python maven \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
