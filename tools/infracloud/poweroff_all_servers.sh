#!/bin/bash

for a in `ironic node-list |head -n -1|tail -n +4|cut -d "|" -f2|tr -d " "`; do
    ironic node-set-power-state "$a" off
done
