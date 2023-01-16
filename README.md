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
# Clone
git clone https://github.com/ctrlo/GADS.git

# Create config.yml
cp config.yml-example config.yml
# Update config file, in particular:
# - plugins->DBIC->dsn
# - plugins->DBIC->user
# - plugins->DBIC->password
# - engines->session->YAML->is_secure
# Make any personal customisations in environments/development_local.yml

# Create database (MySQL)
mysql> CREATE DATABASE gads CHARACTER SET utf8 COLLATE utf8_general_ci;
mysql> GRANT ALL ON gads.* TO 'gads'@'localhost' IDENTIFIED BY 'mysecret';

# Create database (PostgreSQL)
postgres=# CREATE USER gads WITH PASSWORD 'xxx';
postgres=# CREATE DATABASE gads OWNER gads;
# Switch to gads database
gads=# CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;

# Install perl dependencies
cpan .

# Run database seeding script
bin/seed-database.pl
```

# Manually seeding database

Only run this step if the database has not already been seeded with one of the
supplied scripts (such as ```seed-database.pl```)

```
# Deploy database (MySQL)
DBIC_MIGRATION_USERNAME=gads DBIC_MIGRATION_PASSWORD=mysecret \
    dbic-migration -Ilib --schema_class='GADS::Schema' \
    --dsn='dbi:mysql:database=gads' --dbic_connect_attrs \
    quote_names=1 install

# Insert permission fixtures (MySQL)
DBIC_MIGRATION_USERNAME=gads DBIC_MIGRATION_PASSWORD=mysecret \
    dbic-migration -Ilib --schema_class='GADS::Schema' \
    --dsn='dbi:mysql:database=gads' --dbic_connect_attrs \
    quote_names=1 populate --fixture_set permissions


# Deploy database (PostgreSQL)
DBIC_MIGRATION_USERNAME=gads DBIC_MIGRATION_PASSWORD=mysecret \
    dbic-migration -Ilib --schema_class='GADS::Schema' \
    --dsn='dbi:Pg:database=gads' --dbic_connect_attrs \
    quote_names=1 install

# Insert permission fixtures (PostgreSQL)
DBIC_MIGRATION_USERNAME=gads DBIC_MIGRATION_PASSWORD=mysecret \
    dbic-migration -Ilib --schema_class='GADS::Schema' \
    --dsn='dbi:Pg:database=gads' --dbic_connect_attrs \
    quote_names=1 populate --fixture_set permissions


# Insert user into user table.
# Insert instance into instance table.
```

# Finally

```
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

## Managing the deployed database

### Upgrade the deployed database to the latest version

Run this after updating the code:

`perl bin/migrate-db.pl`

### Other useful dbic-migration commands

```
# Dump all data to fixtures
... dump_all_sets --fixture_sets all_tables
# Load all fixture data
... populate --fixture_set all_tables
```

## Data
```
bin/generate.pl # Generate random data
bin/onboard.pl --take-first-enum new.csv # Import random data
```

## Front-end workflow
To get started install all required dependencies by running `yarn install`.

### CSS
CSS is written in SCSS, and compiled.

The main SCSS files live in `scss/`. To compile run `yarn run sass`.

### Javascript
There are two javascript builds present, one to build `dashboard.js` and one to build
`linkspace.js`. The former uses Webpack and is IE9+ compatible. The latter is a simpler
process with Rollup to compile IE8+ compatible code.

Those source files live in `src`. To compile `dashboard.js` run `yarn run ts` and to compile
`linkspace.js` run `yarn run rollup`.

### Combine
To compile all files at the same time run `yarn run start`. This will also monitor for changed
files and will run either `rollup`, `sass` or `ts` when needed. This is the primary command
you want to run when developing.

At this time all compiled files are added to git to support an easier deployment. This should be
migrated to a deployment procedure which builds those files on the fly, allowing the build files
to be removed from git.
