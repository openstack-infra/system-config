#!/bin/bash

cd /usr/share/cacti/cli

HOST_NAME=$1

HOST_TEMPLATE_ID=`php -q /usr/share/cacti/cli/add_device.php \
    --list-host-templates |grep "Linux Host"|cut -f 1`

php -q add_device.php --description="$HOST_NAME" --ip="$HOST_NAME" \
    --template=$HOST_TEMPLATE_ID --version=2 --community="public"

HOST_ID=`php -q add_graphs.php --list-hosts |grep $HOST_NAME|cut -f 1`

TREE_ID=`php -q add_tree.php --list-trees |grep "All Hosts"|cut -f 1`
php -q add_tree.php --type=node --node-type=host --tree-id=$TREE_ID \
    --host-id=$HOST_ID

php -q poller_reindex_hosts.php --id=$HOST_ID

php -q add_graphs.php --list-graph-templates \
    --host-template-id=$HOST_TEMPLATE_ID | \
    while read line ; do
        if echo $line | grep "Known" >/dev/null || [ "$line" == "" ] ; then
            continue
        fi
        TEMPLATE_ID=`echo $line | cut -f 1 -d ' '`
        php -q add_graphs.php --host-id=$HOST_ID --graph-type=cg \
            --graph-template-id=$TEMPLATE_ID
    done

function add_ds_graph {
    TEMPLATE_NAME=$1
    TYPE_NAME=$2
    FIELD_NAME=$3
    FIELD_VALUE=$4

    TEMPLATE_ID=`php -q add_graphs.php --list-graph-templates | \
        grep "$TEMPLATE_NAME"|cut -f 1`
    TYPE_ID=`php -q add_graphs.php --snmp-query-id=$SNMP_QUERY_ID \
        --list-query-types | grep "$TYPE_NAME"|cut -f 1`

    php -q add_graphs.php --host-id=$HOST_ID --graph-type=ds \
        --graph-template-id=$TEMPLATE_ID --snmp-query-id=$SNMP_QUERY_ID \
        --snmp-query-type-id=$TYPE_ID --snmp-field=$FIELD_NAME \
        --snmp-value=$FIELD_VALUE
}

# php -q add_graphs.php --list-graph-templates
# php -q add_graphs.php --snmp-query-id=$SNMP_QUERY_ID --list-query-types

SNMP_QUERY_ID=`php -q add_graphs.php --host-id=$HOST_ID --list-snmp-queries | \
    grep "SNMP - Get Mounted Partitions"|cut -f 1`

add_ds_graph "Host MIB - Available Disk Space" "Available Disk Space" \
    "hrStorageDescr" "/"

SNMP_QUERY_ID=`php -q add_graphs.php --host-id=$HOST_ID --list-snmp-queries | \
    grep "SNMP - Interface Statistics"|cut -f 1`

add_ds_graph "Interface - Traffic (bits/sec)" "In/Out Bits (64-bit Counters)" \
    "ifOperStatus" "Up"
add_ds_graph "Interface - Errors/Discards" "In/Out Errors/Discarded Packets" \
    "ifOperStatus" "Up"
add_ds_graph "Interface - Unicast Packets" "In/Out Unicast Packets" \
    "ifOperStatus" "Up"
add_ds_graph "Interface - Non-Unicast Packets" "In/Out Non-Unicast Packets" \
    "ifOperStatus" "Up"

SNMP_QUERY_ID=`php -q add_graphs.php --host-id=$HOST_ID --list-snmp-queries | \
    grep "ucd/net - Get IO Devices"|cut -f 1`

for disk in $(php -q add_graphs.php --host-id=$HOST_ID --snmp-field=diskIODevice --list-snmp-values | grep xvd[a-z]$) ; do
    add_ds_graph "ucd/net - Device IO - Operations" "IO Operations" \
        "diskIODevice" "$disk"
    add_ds_graph "ucd/net - Device IO - Throughput" "IO Throughput" \
        "diskIODevice" "$disk"
done
