Globally Accessible Data Store (GADS)
=====================================

GADS is designed as an online replacement for spreadsheets being used to store lists of data.

GADS provides a much more user-friendly interface and makes the data easier to maintain. Its features include:

- Allow multiple users to view and update data simultaneously
- Customise data views by user
- Easy version control
- Approval process for updating data fields
- Basic graph functionality
- Red/Amber/Green calculated status indicators for values

# Installation

```
git clone https://github.com/ctrlo/GADS.git

# Create database (e.g. mysql)
mysql> CREATE DATABASE gads CHARACTER SET utf8 COLLATE utf8_general_ci;
mysql> GRANT ALL ON gads5.* TO 'gads'@'localhost' IDENTIFIED BY 'mysecret';

# Deploy database and fixtures
DBIC_MIGRATION_USERNAME=gads DBIC_MIGRATION_PASSWORD=mysecret \
    dbic-migration -Ilib --schema_class='GADS::Schema' \
    --dsn='dbi:mysql:database=gads5' --dbic_connect_attrs \
    quote_names=1 install

# Update example user
mysql> UPDATE user SET email='me@example.com', username='me@example.com';

# Create config.yml (plugins->DBIC - dsn, user, password, )
cp config.yml-example config.yml
# Update config file:
# - plugins->DBIC->dsn
# - plugins->DBIC->user
# - plugins->DBIC->password
# - engines->session->YAML->is_secure

# Spin up application
$ bin/app.pl

# Use password reset functionality to set initial login!
# - Add your user to all permissions (Admin -> Manage Users)
# - Create user groups (Admin -> Manage Groups)
# - Add your user to a group
# - Create fields (Admin -> Data Layout)
# - Add groups to the field
# - Add data!
```

## PostgreSQL

```
create user gads with password 'xxx';
create database gads owner gads;
# Switch to gads database
CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;
DBIC_MIGRATION_USERNAME=gads DBIC_MIGRATION_PASSWORD=mysecret \
    dbic-migration -Ilib --schema_class='GADS::Schema' \
    --dsn='dbi:Pg:database=gads5' --dbic_connect_attrs \
    quote_names=1 install
```

## Other useful dbic-migration commands
```
# Dump all data to fixtures
... dump_all_sets --fixture_sets all_tables
# Load all fixture data
... populate --fixture_set all_tables
```

## Import data
```
bin/layout-download.pl > ~/layout.yaml
bin/layout-import.pl ~/layout.yaml
bin/generate.pl
bin/onboard.pl new.csv
bin/onboard.pl --take-first-enum new.csv
```

