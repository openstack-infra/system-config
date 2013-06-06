#!/bin/bash

tar -X /etc/bup-excludes -cPf - / | bup split -r $1: -n root -q
