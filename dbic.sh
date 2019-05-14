#!/bin/bash
#XXX Please describe the application of this script.
#XXX Move to bin/ or devel/ with a useful name

echo "Using database sds."   #XXX sds?
read -p "root password of the mysql database: " -r -s PASSWORD
echo

if [ -z "$PASSWORD" ]
then echo "No password. Stopped." >&2
     exit 1
fi

dbicdump \
    -o dump_directory=./lib \
    -o components='["InflateColumn::DateTime"]' \
    -o exclude=dbix_class_deploymenthandler_versions \
    GADS::Schema 'dbi:mysql:dbname=gads' \
    root "$PASSWORD"

