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

FROM openjdk:8 as builder

RUN groupadd builder && \
  useradd builder --home-dir /usr/src --create-home -g builder
RUN \
  echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
  && curl -sL https://bazel.build/bazel-release.pub.gpg | apt-key add - \
  && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get update \
  && apt-get install -y bazel nodejs build-essential zip unzip python maven

COPY . /usr/src
RUN chown -R builder /usr/src

USER builder
ARG BAZEL_OPTS
RUN cd /usr/src && bazel build release ${BAZEL_OPTS} && mv bazel-bin/release.war gerrit.war

FROM openjdk:8

RUN apt-get update \
  && apt-get install -y dumb-init \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN addgroup gerrit --system \
  && adduser \
    --system \
    --home /var/gerrit \
    --shell /bin/bash \
    --ingroup gerrit \
    gerrit

USER gerrit
RUN mkdir /var/gerrit/bin
COPY --from=builder /usr/src/gerrit.war /var/gerrit/bin/gerrit.war

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME /var/gerrit/git /var/gerrit/index /var/gerrit/cache /var/gerrit/db /etc/gerrit /var/log/gerrit

RUN ln -s /var/log/gerrit /var/gerrit/logs && \
  ln -s /etc/gerrit /var/gerrit/config

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/bin/java", "-jar", "/var/gerrit/bin/gerrit.war"]
