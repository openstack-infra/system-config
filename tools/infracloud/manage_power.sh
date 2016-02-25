#!/bin/bash
if [ $# -eq 0 ]; then
    echo "No arguments provided. Usage: manage_power.sh [on/off] [optional:server_id]"
    exit 1
fi

# parse power state argument
power_state="$1"
if [ $power_state != "on" ] && [ $power_state != "off" ]; then
    echo "Only on/off values are allowed for power"
    exit 1
fi

# parse server
server=$2
if [ $server ]; then
    echo "Setting server $server power state to ${power_state}"
    ironic node-set-power-state "$server" $power_state
else
    $SERVER_LIST=$(ironic node-list |head -n -1|tail -n +4|cut -d "|" -f2|tr -d " ")
    for a in $SERVER_LIST; do
        echo "Setting server $a power state to ${power_state}"
        ironic node-set-power-state "$a" $power_state
    done
fi
