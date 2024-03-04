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

# Clone
`git clone https://github.com/ctrlo/GADS.git`

# Create config.yml from example

`cp config.yml-example config.yml`

# Update config file (should not be necessary), in particular:
# - plugins->DBIC->dsn
# - plugins->DBIC->user
# - plugins->DBIC->password
# - engines->session->YAML->is_secure
# Make any personal customisations in environments/development_local.yml

## Spin up dev environment with docker

Run `docker compose up`..

Open the application on http://localhost:3000
Login with 'admin@localhost' and password 'qwedsa'

## Manual installation

### Create database (MySQL)

`mysql> CREATE DATABASE gads CHARACTER SET utf8 COLLATE utf8_general_ci;`
`mysql> GRANT ALL ON gads.* TO 'gads'@'localhost' IDENTIFIED BY 'mysecret';`

### Create database (PostgreSQL)

`postgres=# CREATE USER gads WITH PASSWORD 'xxx';`
`postgres=# CREATE DATABASE gads OWNER gads;`

### Switch to gads database
`gads=# CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;`

### Install perl dependencies
`cpan .`

### Seed database with script
`bin/seed-database.pl`

### Seed database manually

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

### Finally

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

---

## Managing the deployed database

### Upgrade the deployed database to the latest version

Run this after updating the code:

`perl bin/migrate-db.pl --upgrade`

### Other useful database migration commands

```
# Print database version information
perl bin/migrate-db.pl --status

# Dump all data to fixtures
perl bin/migrate-db.pl --fixtures=export

# Load all fixture data
perl bin/migrate-db.pl --fixtures=import
```

## Data

```
bin/generate.pl # Generate random data
bin/onboard.pl --take-first-enum new.csv # Import random data
```

## Front-end workflow

This section describes the front-end flow: CSS and JS.
To get started install all required dependencies by running `yarn install`.

### Docker
When you're using `docker` to spin up this application, the CSS and JS
will automatically be compiled and saved in the `public` folder.
The container `frontend` defined in `docker-compose.yml` has the command
to run `webpack` and watch the files.

### Manual

To build the frontend yourself, run the command `yarn run build`.
This will run the command defined in the `package.json`:
```
    "roger": "NODE_ENV=production node node_modules/.bin/webpack --watch --progress --output-path public/",
```
To not build files minified, change to ```minimize: false``` in webpack.config.js

### CSS

CSS is written in SCSS, and compiled.
The main SCSS files live in `src/frontend/css/stylesheets`.
There are two main-entries: `general.scss` and `external.scss`.
Both will compile to their own CSS file. The components that
are included in those files are defined in `src/frontend/components/**/_*.scss`.

### Javascript

There is one javascript build present. The main-entry file is `src/frontend/js/site.js`.
The components that are included in this file is defined in `src/frontend/components/**/index.js`
and `src/frontend/components/**/lib/*.js`.
