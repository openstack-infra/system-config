#!/bin/bash -xe

mkdir -p target/
/usr/bin/xmllint -noent $1 > target/$(basename $1)
