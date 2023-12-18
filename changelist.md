# GADS Changelist

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
