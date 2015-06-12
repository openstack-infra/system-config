#!/bin/bash

ROOT=$(readlink -fn $(dirname $0)/.. )
python $ROOT/tools/sorted_modules_env.py $ROOT/modules.env
