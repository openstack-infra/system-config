#!/bin/sh 

HOME=$PWD
wget https://pypi.python.org/packages/source/z/zuul/zuul-2.0.0.tar.gz#md5=8a0f870a8a83c827124411f5e4cd45b2
gunzip zuul-2.0.0.tar.gz
tar -xvf zuul-2.0.0.tar
cd zuul-2.0.0
python setup.py build
python setup.py install

cd $HOME
git clone git://github.com/openstack-dev/pbr.git
cd pbr
python setup.py build
python setup.py install

cd $HOME
wget https://pypi.python.org/packages/source/g/gear/gear-0.5.4.tar.gz#md5=0dcfee882259cb454d5c34113771117a
gunzip gear-0.5.4.tar.gz
tar -xvf gear-0.5.4.tar
cd gear-0.5.4
python setup.py build
python setup.py install
