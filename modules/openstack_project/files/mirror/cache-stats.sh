#!/bin/bash
for X in 0 1 2 ; do
    HITS=$(grep ' cache hit ' /var/log/apache2/${HOSTNAME}*_808${X}_access.log | wc -l)
    REFRESHES=$(grep ' conditional cache hit: entity refreshed ' /var/log/apache2/${HOSTNAME}*_808${X}_access.log | wc -l)
    MISSES=$(grep ' cache miss: ' /var/log/apache2/${HOSTNAME}*_808${X}_access.log | wc -l)

    echo "Port 808${X} Cache Hits: $HITS"
    echo "Port 808${X} Cache Refresshes: $REFRESHES"
    echo "Port 808${X} Cache Misses: $MISSES"
    echo ""
done
