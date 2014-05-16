#!/bin/bash -e

ROOT=$(readlink -fn $(dirname $0))
MODULE_PATH="${ROOT}/modules:/etc/puppet/modules"

if [ ! -d applytest ] ; then
    mkdir applytest
fi

csplit -sf applytest/puppetapplytest manifests/site.pp '/^$/' {*}
sed -i -e 's/^[^[:space:]]/#&/g' applytest/puppetapplytest*
sed -i -e 's@hiera(.\([^.]*\).,\([^)]*\))@\2@' applytest/puppetapplytest*

for f in `find applytest -name 'puppetapplytest*' -print` ; do
    sudo puppet apply --modulepath=${MODULE_PATH} --noop --verbose --debug $f >/dev/null
done
