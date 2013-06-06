#!/bin/bash

mysqldump -A --opt > /var/backup/mysql-dump.sql
tar -X /etc/bup-excludes -cPf - / | bup split -r $1: -n root -q
