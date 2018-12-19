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

ARG GITEA_VERSION=v1.6.0
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

FROM debian:testing
LABEL maintainer="infra-root@openstack.org"

EXPOSE 22 3000

RUN apt-get update && apt-get -y install \
    bash \
    ca-certificates \
    curl \
    gettext \
    git \
    openssh-client \
    tzdata \
    pandoc \
 && rm -rf /var/lib/apt/lists/*

RUN addgroup \
    --system --gid 1000 \
    git && \
  adduser \
    --system --no-create-home --disabled-login \
    --home /data/git \
    --shell /bin/bash \
    --uid 1000 \
    --gid 1000 \
    git && \
  echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd

COPY --from=build-env /go/src/code.gitea.io/gitea/gitea /app/gitea/gitea
COPY --from=build-env /go/src/code.gitea.io/gitea/docker /
RUN ln -s /app/gitea/gitea /usr/local/bin/gitea

ENV USER git
ENV GITEA_CUSTOM /data/gitea
VOLUME ["/data"]
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/app/gitea/gitea"]
USER 1000:1000
