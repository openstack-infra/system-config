#!/bin/bash -xe

rm -fr ~/.m2
rm -fr ~/.java
./tools/version.sh --release
mvn clean package -Dgerrit.include-documentation=1 -X
./tools/version.sh --reset
