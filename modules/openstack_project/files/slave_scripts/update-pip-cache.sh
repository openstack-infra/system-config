#!/bin/bash -xe

mkdir -p ~/cache/pip
VENV=`mktemp -d`
virtualenv --no-site-packages $VENV
cd $VENV
. bin/activate
PIP_DOWNLOAD_CACHE=~/cache/pip pip install `cat ~/devstack/files/pips/*`
cd
rm -fr $VENV
