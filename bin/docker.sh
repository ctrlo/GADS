#!/bin/bash
cd ../
psql gads -U gads -h db -c "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"
perl ./bin/seed-database.pl --initial_username=$1 --instance_name=test --site=localhost
perl -Ilib -MDancer2 -MDancer2::Plugin::Auth::Extensible -wE "user_password username => 'robin.corba@digitpaint.nl', new_password => $2"
psql gads -U gads -h db -c "UPDATE public.site SET host = 'localhost'"
psql gads -U gads -h db -c "UPDATE public.user SET account_request = 0, pwchanged = NOW();"
./bin/app.pl