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

## PostgreSQL

```
create user gads with password 'xxx';
create database gads owner gads;
psql -U postgres gads < sql/schema.sql
```

```
insert into instance (name) values ('GADS');
insert into "user" (email,username,firstname,surname,value) values ('me@example.com','me@example.com','Joe','Bloggs','Bloggs, Jo');
\copy permission (name,description,"order") FROM 'sql/permissions.csv' DELIMITER ',' CSV;
insert into user_permission (user_id,permission_id) values (1,1);
```

## Import data
```
bin/layout-download.pl > ~/layout.yaml
bin/layout-import.pl ~/layout.yaml
bin/generate.pl
bin/onboard.pl new.csv
bin/onboard.pl --take-first-enum new.csv
```

