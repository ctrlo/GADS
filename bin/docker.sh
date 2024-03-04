#!/bin/bash

echo "Wait for database to start..."
chmod +x /app/bin/wait-for-it.sh
/app/bin/wait-for-it.sh "db:5432"  -t 3

echo "Create citext extension..."
psql gads -U gads -h db -c "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"

echo "Seed database..."
perl /app/bin/seed-database.pl --initial_username=$1 --instance_name=datasheet --site=$3

echo "Add user '$1'..."
perl -Ilib -MDancer2 -MDancer2::Plugin::Auth::Extensible -wE "user_password username => '$1', new_password => '$2'"

echo "Set new user password changed to 'now'..."
psql gads -U gads -h db -c "UPDATE public.user SET account_request = 0, pwchanged = NOW();"

echo "Set site host to '$3'..."
psql gads -U gads -h db -c "UPDATE public.site SET host = '$3'"

echo "Start the perl application.."
/app/bin/app.pl
