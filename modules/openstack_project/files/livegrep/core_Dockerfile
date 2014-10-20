FROM ubuntu:14.04

MAINTAINER Spencer Krum <nibz@cat.pdx.edu>

RUN  \
 apt-get update && \
 apt-get install -y libgflags-dev libgit2-dev libjson0-dev libboost-system-dev libboost-filesystem-dev libsparsehash-dev golang git build-essential automake mercurial


RUN cd /opt && git clone https://github.com/nibalizer/livegrep

#RUN cd /opt/livegrep && git checkout master

RUN cd /opt/livegrep && GOPATH= make -j4 all

#RUN cd /opt/livegrep/livegrep && GOPATH=/home/livegrep/.gopath go get 
#RUN cd /opt/livegrep/livegrep && GOPATH=/home/livegrep/.gopath go build
