#!/usr/bin/env bash

if [[ ! -f /etc/anon_subunit_user.done ]] ; then
    mysql --username="$1" --pasword="$2" --database="$3" --execute="CREATE USER 'query'@'*' IDENTIFIED BY 'query'; GRANT SELECT PRIVILEGES ON $3.* TO 'query'@'*';"
    return_code=$?
    if [[ $return_code -eq 0 ]] ; then
        touch /etc/anon_subunit_user.done
    fi
    exit $return_code
fi
