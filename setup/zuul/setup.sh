#!/bin/sh 

# Set date and time correctly (ntp preferred)

# Setup id_rsa* and config in ~/.ssh/.
config=<<EOF
UserKnownHostsFile=/home/zuul/known_hosts
StrictHostKeyChecking=no
EOF

echo $config > ~/.ssh/config

service zuul-merger restart
service zuul restart

