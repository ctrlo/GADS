# GADS Changelist

-------

**Version**: 2.3.0
**Released**: 04th March 2024

-------

## QoL changes

- Reporting changes
  - Added ability to add logo in admin settings
  - Added security marking - this can be set at admin, instance (table), and report level
- Made creation of views clearer
- Added searchable dropdowns to view filters

## Fixes

- Fixed typeahead bugs
- Added RAG values that were missing to filters
- Fixed `OwnerDocument is null` error in tables
- Fixed globe bug introduced with Typeahead functionality
- Fixed incorrect rendering of readonly fields
- Fixed incorrect use of Put in dashboards

## Other

- Added Docker development scripts

-------

**Version**: 2.2.0
**Released**: 26th January 2024

-------

## QoL changes

- Typeahead on column search for certain fields
- Search on view filters
- Added full screen control to audit screen
- Drag and Drop modified on file upload in order to improve user experience

## fixes

- Header and formatting for multival calc fields fixed
- Fixed misplaced chevron for viewing record details
- Moved over to typeahead.js from previous typeahead library as previous library was deprecated
- Modified header and value placement for multival calc field views

## Development changes

- Changed webpack config for ease of development
- Added build:dev and test:watch yarn tasks for development use

-------

**Version**: 2.1.0
**Released**: 18th December 2023

-------

## Features

- Custom PDF reports now available for download
- Markdown now has live preview on edit
- Full screen mode now added for large datasets

## QoL Changes

- New typeahead library
- User request notes now visible on account requests in create user wizard
- Users able to have view limits set
- Additional user fields added
- Searchable Account fields added
- Download options for records made clearer
- Loading display no longer in center of table (meaning user had to scroll to see it)
- Scroll bar added to long widgets
- Notes field added for when editing columns
- User export speeds now lower on larger datasets
- Audit defaults to 24h
- Remove button added to alerts
- Provided admins the ability to manage the alerts of another user
- Added a spin wheel when searching for cur-vals
- Modified the created_by and edited_by fields so they can now be selected for more info.
- Calc fields now automatically resize
- Calc fields can now be resized manually

## fixes

- Fix for internal ticket 1491
- Fix for no click event on page or page-length change for user accounts
- Fix for notes field error on editing users
- Fix for inability to remove dept, title, org, or team
- Fix to stop editing fields that should be read-only on user's editing their details
- Fix for users not being sent an email upon approving account requests
- Fix for cloning instances dependent fields
- Fix to stop read-only values being cloned with an instance
- Users can't edit/view their own internal notes field
- Fixed panic for notes field
- Mandatory Dropdowns fixed on user creation
- Now able to edit region and organisation names
- Sorting on PDU or Region within the users page no longer results in an error
- Fixed issue where multi-value mandatory fields were not erroring correctly
