# GADS Changelist

-------

**Version**: 2.5.6
**Released**: 17-10-2024

-------

## Fixes

- Fixed error in aggregate function causing created by and updated by to error

-------

**Version**: 2.5.5
**Released**: 02-10-2024

-------

## New features

- Added renaming to document uploads

## Fixes

- Fixed error when sending notification emails
- Fixed global report visibility
- Fixed curval edits
- Fixed deleted reports visibility
- Fixed display for datatables

-------

**Version**: 2.5.4
**Released**: 22-09-2024

-------

## Fixes

- Fix saving of report groups on initial report creation
- Fix download of reports
- Fix same report showing multiple times
- Fix exception when loading metadata for some records

-------

**Version**: 2.5.3
**Released**: 20-09-2024

-------

## Fixes

- Fix render of metadata values in curval

-------

**Version**: 2.5.2
**Released**: 16-09-2024

-------

## Fixes

- Fix version date/time in chronology
- Fix metadata in CSV downloads

-------

**Version**: 2.5.1
**Released**: 11-09-2024

-------

## Fixes

- Fix PDF downloads of records
- Bump JS version

-------

**Version**: 2.5.0
**Released**: 03-09-2024

-------

## New Features

- Groups will now be used to control permissions to view/download reports

## QoL Changes

- New version of `Net::SAML2`
- Removed extra requests when pulling data to improve efficiency
- Improved upload controls
- Input components now separated into different files
- Code in common.ts cleaned up and unnecessary code removed
- Added Jest test mocks
- Updated GitHub Actions for CI/CD

## Fixes

- Full screen datatables now allows filtering and sorting
- ipairs now no longer misses first element in front-end calcs
- Fix incorrect forward after first login
- DataTables search bar is now correct width

-------

**Version**: 2.4.0
**Released**: 22-07-2024

-------

## New Features

- Contextual help integrated into new view interface
- Filters now added to `Person` fields allowing to filter by
  - Department
  - Title
  - Organisation
  - Team
- Purging of records from view now possible - please note **this is a destructive action and should be the exception for deletion, not the rule**
- Added Cypress for integration testing with
  - Login tests
  - Homepage Tests
  - Settings Test
  - User Group Tests
  - File Upload Tests
  - Table Wizard Tests
  - Basic Layout Tests

## QoL Changes

- New interface for building views
- Calc cache optimisation
- Port on launch via `./bin/app.pl` can be set by using the environment variable `PORT` - defaults to 3000
- Buttons seperated into different files
  - Started unit test implementation for buttons where possible now implementations are cleaner
- Show-in-edit for `Calc` fields means they can be used for on edit calcs whilst still being hidden
- Made download options clearer within menus for use with extensions
- Added browserlists to `package.json`
- Can exit fullscreen using escape key
- Higher use of chunks in order to limit size of `site.js` on webpack

## Fixes

- Bug in QueryBuilder with dynamic typeahead no longer causes QueryBuilder to not load correctly
- View filtering typeahead was not saving when no text was entered and an option was selected - menu now only shows when 1+ character is typed
- Popover arrow now displays correctly
- Fix for scoping issues in some AJAX requests and other areas
- Fixed Webdriver Tests
- Fix for bug in admin and shared view creation
- Fullscreen now works correctly when clicking label
- Audit now uses local timezone on display
- Fixed error when building webpack in timeline code

## Other

- Re-written readme.md as this was out of date
- Added (very basic) Rex deployment for testing environments
  - This will probably need modification for specific systems but is, at worst, a good starting point

-------

**Version**: 2.3.3
**Released**: 09th May 2024

-------

## Hotfix

- Fix for extra request on curval fields

-------

**Version**: 2.3.2
**Released**: 09th May 2024

-------

## Hotfix

- Fix for typeahead issues
  - Increased efficiency of typeahead response times
  - Fixed bug causing locking issues with PSQL
  - Fix for searching for people where results were not displaying correctly

-------

**Version**: 2.3.1
**Released**: 10th April 2024

-------

## Hotfix

- Fix for fullscreen bugs
  - Fullscreen now renders with correct width
  - Label now causes fullscreen to be triggered correctly

-------

**Version**: 2.3.0
**Released**: 26th March 2024

-------

## QoL changes

- Reporting changes
  - Added ability to add logo in admin settings
  - Added security marking - this can be set at admin, instance (table), and report level
- Made creation of views clearer
- Added searchable dropdowns to view filters
- Multi-value displays are now clearer for string values

## Fixes

- Fixed typeahead bugs
- Added RAG values that were missing to filters
- Fixed `OwnerDocument is null` error in tables
- Fixed globe bug introduced with Typeahead functionality
- Fixed incorrect rendering of readonly fields
- Fixed incorrect use of Put in dashboards
- Fixed layout referenced in report stopping deletion of layout

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
