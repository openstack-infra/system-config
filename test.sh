#!/bin/bash -e

ROOT=$(readlink -fn $(dirname $0))
MODULE_PATH="${ROOT}/modules:/etc/puppet/modules"

if [ ! -d applytest ] ; then
    mkdir applytest
fi

csplit -sf applytest/puppetapplytest manifests/site.pp '/^$/' {*}
sed -i -e 's/^[^[:space:]]/#&/g' applytest/puppetapplytest*
sed -i -e 's@hiera(.\([^.]*\).,\([^)]*\))@\2@' applytest/puppetapplytest*

find applytest -name 'puppetapplytest*' -print0 | xargs -0 -P $(nproc) -n 1 -I filearg sudo puppet apply --modulepath=${MODULE_PATH} --noop --verbose --debug filearg > /dev/null
