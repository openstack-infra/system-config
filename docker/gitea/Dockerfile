# Copyright (c) 2018 Red Hat, Inc.
# Copyright (c) 2016 The Gitea Authors
# Copyright (c) 2015 The Gogs Authors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

###################################
#Build stage
FROM golang:1.11-stretch AS build-env

LABEL maintainer="infra-root@openstack.org"

ARG GITEA_VERSION=v1.7.4
ENV TAGS "bindata $TAGS"

#Build deps
RUN apt-get update && apt-get -y install build-essential git \
  && mkdir -p ${GOPATH}/src/code.gitea.io/gitea

#Setup repo
RUN git clone https://github.com/go-gitea/gitea ${GOPATH}/src/code.gitea.io/gitea
WORKDIR ${GOPATH}/src/code.gitea.io/gitea

#Checkout version if set
RUN if [ -n "${GITEA_VERSION}" ]; then git checkout "${GITEA_VERSION}"; fi \
 && make clean generate build

###################################
# Basic system setup common to all containers in our pod

FROM debian:testing as base

RUN apt-get update && apt-get -y install \
    bash \
    ca-certificates \
    curl \
    gettext \
    git \
    openssh-client \
    tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN addgroup --system --gid 1000 git \
  && adduser \
    --system --no-create-home --disabled-login \
    --home /data/git \
    --shell /bin/bash \
    --uid 1000 \
    --gid 1000 \
    git \
  && echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd \
  && mkdir /custom

# Copy the /etc config files and entrypoint script
COPY --from=build-env /go/src/code.gitea.io/gitea/docker /
# Copy our custom sshd_config
COPY sshd_config /etc/ssh/sshd_config

# Copy the app
COPY --from=build-env /go/src/code.gitea.io/gitea/gitea /app/gitea/gitea
RUN ln -s /app/gitea/gitea /usr/local/bin/gitea

# Copy our custom templates
COPY custom/ /custom/

ENV GITEA_CUSTOM /custom

###################################
# The gitea image
FROM base as gitea

RUN apt-get update && apt-get -y install pandoc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

EXPOSE 3000
ENV USER git
VOLUME ["/data"]
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/app/gitea/gitea", "web"]
USER 1000:1000

###################################
# The openssh server image
FROM base as gitea-openssh

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" \
    install openssh-server \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /run/sshd

COPY sshd-entrypoint.sh /usr/bin/entrypoint

EXPOSE 22
VOLUME ["/data"]
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/usr/sbin/sshd", "-D"]
