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
CHALLENGE_ALIAS_DOMAIN=${CHALLENGE_ALIAS_DOMAIN:-acme.opendev.org}
# default to staging to avoid production errors
LETSENCRYPT_STAGING=${LETSENCRYPT_STAGING:--staging}
LOG_FILE=${LOG_FILE:-/var/log/acme.sh/acme.sh.log}

if [[ ${1} == "issue" ]]; then
    shift;
    for arg in "$@"; do

        $ACME_SH ${STAGING} \
            --cert-home ${CERT_HOME} \
            --no-color \
            --yes-I-know-dns-manual-mode-enough-go-ahead-please \
            --issue \
            --dns \
            --challenge-alias ${CHALLENGE_ALIAS_DOMAIN} \
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
elif [[ ${1} == "selfsign" ]]; then
    shift;
    for arg in "$@"; do
        # TODO(ianw): do we care about the extra domains for
        # self-signed test keys?
        read -r -a domain_array <<< "$arg"
        domain=${domain_array[1]}
        mkdir -p ${CERT_HOME}/${domain}
        cd ${CERT_HOME}/${domain}
        openssl genrsa -out ${domain}.key 2048
        openssl rsa -in ${domain}.key -out ${domain}.key
        openssl req -sha256 -new -key ${domain}.key -out ${domain}.csr -subj '/CN=localhost'
        openssl x509 -req -sha256 -days 365 -in ${domain}.csr -signkey ${domain}.key -out ${domain}.cer
        cp ${domain}.cer fullchain.cer
else
    echo "Unknown driver arg: $1"
    exit 1
fi

