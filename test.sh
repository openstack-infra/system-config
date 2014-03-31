find . -iname '*.pp' | xargs puppet parser validate --modulepath=`pwd`/modules
for f in `find . -iname *.erb` ; do
    erb -x -T '-' $f | ruby -c >/dev/null || echo "Error in $f"
done

if [ ! -d applytest ] ; then
    mkdir applytest
fi

csplit -sf applytest/puppetapplytest manifests/site.pp '/^$/' {*}
sed -i -e 's/^[^[:space:]]/#&/g' applytest/puppetapplytest*
sed -i -e 's/hiera..sysadmins../["admin"]/' applytest/puppetapplytest*
sed -i -e 's/hiera..listadmins../["admin"]/' applytest/puppetapplytest*
sed -i -e 's/hiera.*/PASSWORD,/' applytest/puppetapplytest*
for f in `find applytest -name 'puppetapplytest*' -print` ; do
    puppet apply --modulepath=./modules:/etc/puppet/modules -v --noop --debug $f >/dev/null
done
