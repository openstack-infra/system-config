#!/bin/bash
#
# Copyright 2016 IBM, Inc.
# Copyright 2012 Hewlett-Packard Development Company, L.P. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# purge tables of "deleted" records

# use the -n option to enable dry run mode
unset DRY_RUN

# tables to arhive deleted records from
DATABASE=nova
TABLES="security_group_rules security_group_instance_association \
security_groups instance_info_caches instances reservations"
FKTABLES="block_device_mapping instance_metadata instance_system_metadata \
instance_actions instance_faults virtual_interfaces fixed_ips \
security_group_instance_association migrations instance_extra"
TABLES="${TABLES} ${FKTABLES}"

## process the command line arguments
while getopts "hnad:H:u:p:s:" opt; do
    case $opt in
        h)
            echo "openstack_db_delete.sh - delete server records"
            echo "Records are deleted from the following tables:"
            echo
            for TABLE in ${TABLES}; do
                echo "    ${DATABASE}.${TABLE}"
            done
            echo
            echo "Options:"
            echo " -n dry run mode"
            echo " -d db name"
            echo " -H db hostname"
            echo " -u db username"
            echo " -p db password"
	    echo " -s server id to delete"
            echo " -h (show help)"
            exit 0
        ;;
        n)
            DRY_RUN=1
        ;;
        d)
            DATABASE=${OPTARG}
        ;;
        H)
            HOST="-h${OPTARG}"
        ;;
        u)
            USER="-u${OPTARG}"
        ;;
        p)
            PASS="-p${OPTARG}"
        ;;
        s)
            SERVERID=$OPTARG
	;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
        ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
        ;;
    esac
done

function do_database {
  if [ -z $DRY_RUN ]; then
    mysql $USER $HOST -e "$1" $DATABASE
  else
    echo mysql $USER $HOST -e "$1" $DATABASE
  fi
}

echo
echo `date` "OpenStack Database Deleter starting.."
echo

echo `date` "Purging nova.instance_actions_events of deleted instance data"
# this is back to front (on delete if you can find a record in instances
# flagged for deletion)
# --where 'EXISTS(SELECT * FROM instance_actions, instances WHERE
# instance_actions.id=instance_actions_events.action_id AND
# instance_actions.instance_uuid=instances.uuid AND instances.deleted!=0)'

if [ ! -z $SERVERID ] ; then
    echo "Deleting $SERVERID from instance_actions_events"
    do_database "delete from instance_actions_events where action_id = (select id from instance_actions where instance_uuid=$SERVERID);"

    for TABLE in ${FKTABLES}; do
        echo "Deleting $SERVERID foreign key references from $TABLE"
        do_database "delete from $TABLE where instance_uuid = $SERVERID;"
    done

    echo "Deleting $SERVERID from instance_actions"
    do_database "delete from instance_actions where instance_uuid = $SERVERID;"

    echo "Deleting $SERVERID from instances"
    do_database "delete from instances where uuid = $SERVERID;"

else

    echo "Deleteing from instance_actions_events"
    do_database "delete from instance_actions_events where action_id = ANY (select a.id from instance_actions a join instances i on i.uuid=a.instance_uuid where i.deleted!=0);"

    for TABLE in ${FKTABLES}; do
	echo "Deleting foreign key references from $TABLE"
        do_database "delete from $TABLE where instance_uuid = ANY (select uuid from instances where deleted!=0);"

    done

    for TABLE in ${TABLES}; do
	echo "Deleting deleted!=0 from $TABLE"
        do_database "delete from $TABLE where deleted!=0;"
    done
fi

echo
echo `date` "OpenStack Database deleter finished."
echo
