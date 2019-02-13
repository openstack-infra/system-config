#!/bin/bash

# Take output like:
#  [Thu Feb 14 13:44:37 AEDT 2019] Domain: '_acme-challenge.test.opendev.org'
#  [Thu Feb 14 13:44:37 AEDT 2019] TXT value: 'QjkChGcuqD7rl0jN8FNWkWNAISX1Zry_vE-9RxWF2pE'
#
# and turn it into:
#
# _acme-challenge.test.opendev.org:QjkChGcuqD7rl0jN8FNWkWNAISX1Zry_vE-9RxWF2pE
#
# Ansible then parses this back to a dict

ACME_SH=${ACME_SH:-/opt/acme.sh/acme.sh}
CERT_HOME=${CERT_HOME:-/etc/letsencrypt-certs}
CHALLENGE_ALIAS_DOMAIN=${CHALLENGE_ALIAS_DOMAIN:-acme-opendev.org}
LOG_FILE=${LOG_FILE:-/var/log/acme.sh/acme.sh.log}

if [[ ${1} == "issue" ]]; then
    shift;
    for arg in "$@"; do

        $ACME_SH \
            --cert-home ${CERT_HOME} \
            --no-color \
            --yes-I-know-dns-manual-mode-enough-go-ahead-please \
            --issue \
            --dns \
            --challenge-alias ${CHALLENGE_ALIAS_DOMAIN} \
            --staging \
            $arg 2>&1 | tee -a ${LOG_FILE} | \
                egrep 'Domain:|TXT value:' | cut -d"'" -f2 | paste -d':' - -
                # shell magic ^ is
                #  - extract everything between ' '
                #  - stick every two lines together, separated by a :
    done
elif [[ ${1} == "renew" ]]; then
    shift;
    for arg in "$@"; do
        $ACME_SH \
            --cert-home ${CERT_HOME} \
            --no-color \
            --yes-I-know-dns-manual-mode-enough-go-ahead-please \
            --renew \
            --staging \
            $arg 2>&1 | tee -a ${LOG_FILE}
    done
else
    echo "Unknown driver arg: $1"
    exit 1
fi

