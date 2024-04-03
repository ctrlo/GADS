# Globally Accessable Datastore (GADS)

## What is GADS?

GADS is the Globally Accessable Data Store[^1] - it is designed for a powerful online replacement of Spreadsheets and other (semi) flat data stores with the power to perform tasks that don't quite require a fully-fledged database, but a spreadsheet can't quite meet.

GADS provides a much more user-friendly interface and makes the data easier to maintain; it's features include[^2]:

- Allow multiple users to view and update data simultaneously
- Customise data views by user
- Easy version control
- Approval process for updating data fields
- Basic graph functionality[^3]
- Red/Amber/Green calculated status indicators for values
- Complex calculated values

## What is this document?

This document explains how to set up GADS V2+ on your local system for development or usage within your environment

## At whom is this document aimed?

This document is aimed at technical professionals who require a solution for multi-user spreadsheet access, or engineers who wish to help improve the system.

## Languages used

GADS as a system uses a number of languages in it's implementation, these include (but are not limited to):

- Perl
- JavaScript
- TypeScript
- SCSS

## Contributing

Contributing to this project can be achieved through opening pull requests to the UIUX[^4] branch. The following requirements are to be met before a pull request is even considered:

- All code and exernal libraries are to be fully [ISO:27001](https://www.iso.org/standard/27001) compliant
- All pull requests and commit messages are to have explicit titles, as well as comprehensive descriptions as far as is possible
- All code is to either use "Really Obvious Code" or comment your code so that the maintainers (and possibly you, further down the line) can ascertain the purpose easily
- All code is to pass all tests included within the suite - custom code is to include unit tests where possible, but changes to current unit tests are only to be performed with _full_ justification. These tests include:
  - Perl unit tests
  - Jest JS/TS tests
  - Cypress E2E tests[^5]

### Development Requirements

To develop for this project the following is required as a minimum:

- Git
- Perl
- Yarn

#### Frontend workflow

This section describes the front-end flow: CSS and JS.
To get started install all required dependencies by running `yarn install`.

To build the JS/CSS (only required if you change anything) use `yarn build` for "release" and `yarn build:dev` for development

To run JEST tests, run `yarn test`, to watch any tests and run them according to any code changes run `yarn test:dev`

## Installation

### The easy way - (R)?ex

Probably the quickest and easiest way to set up GADS within your environment is using [(R)?ex](http://rexify.org). Set up Rex on your system, and then run `rex -b setup` within the gads root (obviously clone using `git clone https://github.com/ctrlo/GADS -b uiux` first and chdir into the GADS directory) to set up a basic GADS environment on your system.

### Manual package installation

GADS is complicated, there are a _lot_ of packages required - to install GADS locally you need to install GCC, G++, Make, Perl, and CPAN, then:

```bash
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

### Running the application

To run the application, once you've got the hard stuff out of the way (see above), you just need to run `./bin/app.pl` and use the password reset function to retrieve a password for your created user!

## DB usage

### Upgrading

If there is a change to the DB schema, by yourself, or on a release of a new version, you just need to run `perl ./bin/migrate-db.pl --upgrade`

### Useful DB commands

There are also a number of useful DB commands, these are:

- `perl ./bin/migrate-db.pl --status` - Print DB version information
- `perl ./bin/migrate-db.pl --fixtures=export` - Dump all data to fixtures
- `perl ./bin/migrate-db.pl --fixtures=import` - Load all fixture data

[^1] Isn't Data Store one word, or is it hyphenated?

[^2] Taken from the original Readme.md - this probably needs significant changes

[^3] This functionality is currenty undergoing significant changes and improvements

[^4] Let's be honest, we want them to contribute to their own branch (i.e. have a `contributions` branch for use for external contributions?)

[^5] The implementation of this is underway, but not yet included in this version
