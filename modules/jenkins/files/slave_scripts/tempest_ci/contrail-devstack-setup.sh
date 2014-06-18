git clone https://github.com/dsetia/devstack.git
cp devstack/contrail/localrc-ci devstack/localrc
python fix_localrc.py
cd devstack
./stack.sh
