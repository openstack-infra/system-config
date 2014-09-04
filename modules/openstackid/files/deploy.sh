#!/bin/bash -e
#
# Site deployment tool
#
# Commands:
#   init @sitealias http://example.com/source.tar.gz
#   status @sitealias
#   update @sitelias http://example.com/source.tar.gz
#   rollback @sitealias
#
#



TOP_DIR=$(cd $(dirname "$0") && pwd)
source $TOP_DIR/functions

if [ ! -r $TOP_DIR/deployrc ]; then
    echo "ERROR: missing deployrc - did you grab more than just deploy.sh?"
    exit 1
fi
source $TOP_DIR/deployrc

command="${1}"
case $command in
    init)
        site_init ${2}
        ;;
    status)
        site_status ${2}
        ;;
    update)
        site_update ${2}
        ;;
    *)
        print_help
        exit 1
        ;;
esac
