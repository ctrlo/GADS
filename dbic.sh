#!/bin/bash

echo Using database sds. Please enter the root password of the mysql database:
read PASSWORD

dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' GADS::Schema 'dbi:mysql:dbname=sds' root $PASSWORD

