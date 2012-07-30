#!/bin/bash -xe

csplit -sf puppetapplytest manifests/site.pp '/^$/' {*}
sed -i -e 's/^[^[:space:]]/#&/g' puppetapplytest*
find ./ -name puppetapplytest* -print -exec cat {} \; -exec puppet apply --modulepath=./modules -v --noop --debug {} \;
