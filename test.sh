#!/bin/bash -e

ROOT=$(readlink -fn $(dirname $0))
MODULE_PATH="${ROOT}/modules:/etc/puppet/modules"

if [ ! -d applytest ] ; then
    mkdir applytest
fi

csplit -sf applytest/puppetapplytest manifests/site.pp '/^$/' {*}
sed -i -e 's/^[^][:space:]$]/#&/g' applytest/puppetapplytest*
sed -i -e 's@hiera(.\([^.]*\).,\([^)]*\))@\2@' applytest/puppetapplytest*
mv applytest/*00 applytest/head  # These are the top-level variables defined in site.pp

if [ `lsb_release -i -s` == 'CentOS' ]; then
    if [ `lsb_release -r -s` =~ '6' ]; then
	CODENAME='centos6'
    fi
elif [ `lsb_release -i -s` == 'Ubuntu' ]; then
    CODENAME=`lsb_release -c -s`
fi

FOUND=0
for f in `find applytest -name 'puppetapplytest*' -print` ; do
    if grep "Node-OS: $CODENAME" $f; then
	cat applytest/head $f > $f.final
	FOUND=1
    fi
done

if [ $FOUND == "0" ]; then
    echo "No hosts found for node type $CODENAME"
    exit 1
fi

grep -v 127.0.1.1 /etc/hosts >/tmp/hosts
HOST=`echo $HOSTNAME |awk -F. '{ print $1 }'`
echo "127.0.1.1 $HOST.openstack.org $HOST" >> /tmp/hosts
sudo mv /tmp/hosts /etc/hosts

for filearg in `find applytest -name 'puppetapplytest*.final' -print0`; do
   cat $filearg
   sudo puppet apply --modulepath=${MODULE_PATH} --noop --verbose --debug $filearg
done
