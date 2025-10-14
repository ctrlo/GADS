import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import {
  ICodeLayoutBuilder,
  ICurvalLayoutBuilder,
  IDropdownLayoutBuilder,
  ILayoutBuilder
} from "../../support/builders/layout/interfaces";
import { goodPassword, goodUser } from "../../support/constants";


// List of pages to test
const pagesToTest = [
  '/?did=1', 
  '/file/',
  '/settings/',
  '/settings/title_overview/',
  '/settings/title_add/',
  '/settings/organisation_overview/',
  '/settings/organisation_add/',
  '/settings/default_welcome_email/',
  '/settings/user_editable_personal_details/',
  '/settings/report_defaults/',
  '/user_overview/',
  '/user_requests/',
  '/user/1',
  '/myaccount',
  '/table/',
  '/table1/view/0',
  '/table1/data',
  '/table1/report',
  '/table1/report/add',
  '/table1/edit',
  '/table1/topics',
  '/table1/permissions',
  '/table1/data?viewtype=graph',
  '/table1/data?viewtype=timeline',
  '/table1/historic_purge'
];
const table_shortname = "table1";

 before(() => {
    cy.log("login").login(goodUser, goodPassword);
    cy.log("update user groups").addUserToDefaultGroup("test@example.com", "check");
    cy.log("setup table permissions");
    const permissionObject: Record<string, boolean> = {};
    [
      "Bulk import records",
      "Purge deleted records",
      "Delete records",
      "Bulk delete records",
      "Manage views"
    ].forEach((permissionName) => {
      permissionObject[permissionName] = true;
    });
    cy.setTablePermissionsByShortName(table_shortname, permissionObject);
    cy.addUserToDefaultGroup('test@example.com');
    cy.log("create layouts");
    cy.populateTableWithLayouts("my_table_shortname");
    cy.clearImports(table_shortname);
    cy.bulkImportRecords();
    cy.clearImports(table_shortname);
    cy.logout();
  });
  
  after(() => {
    cy.deleteAllData("table1");
    cy.purgeAllDeletedData("table1");
    cy.cleanTableOfLayouts("table1");
    cy.clearAllTablePermissions("table1");
    cy.addUserToDefaultGroup("test@example.com", "uncheck");
  });

describe('Accessibility Tests (WCAG AA) - All Pages', () => {
  beforeEach(() => {
    cy.log("Logging in...");
    cy.login(goodUser, goodPassword);
  });

  pagesToTest.forEach((page) => {
    describe(`Page: ${page}`, () => {
      beforeEach(() => {
        cy.visit(`http://localhost:3000${page}`);

        // Expand all collapsibles if present
        cy.get('body').then(($body) => {
          const collapsibles = $body.find('[data-toggle="collapse"]');
          if (collapsibles.length > 0) {
            cy.log('Expanding collapsible sections...');
            cy.get('[data-toggle="collapse"]').each(($btn) => {
              cy.wrap($btn).click({ force: true });
            });
          } else {
            cy.log('No collapsible elements on this page');
          }
        });

        // Wait briefly to ensure UI settles before scanning
        cy.wait(200);

        cy.injectAxe();
      });

      it('has no WCAG 2.1 AA violations', () => {
        cy.checkA11y(null, {
          runOnly: {
            type: 'tag',
            values: ['wcag2aa']
          }
        }, logViolations);
      });

      it('has no color contrast issues', () => {
        cy.checkA11y(null, {
          runOnly: {
            type: 'rule',
            values: ['color-contrast']
          }
        }, logViolations);
      });

      it('has valid ARIA and landmark structure', () => {
        cy.checkA11y(null, {
          runOnly: {
            type: 'rule',
            values: [
              'aria-valid-attr',
              'aria-valid-attr-value',
              'region',
              'page-has-heading-one',
              'document-title',
              'label',
              'link-name',
              'image-alt'
            ]
          }
        }, logViolations);
      });
    });
  });
});

// Function to log WCAG violations
function logViolations(violations) {
  if (violations.length) {
    cy.task('log', `${violations.length} accessibility violation${violations.length === 1 ? '' : 's'} detected`);
    violations.forEach(({ id, impact, description, help, nodes }) => {
      cy.task('log', `[${impact}] ${id}: ${description}\nHelp: ${help}`);
      nodes.forEach(({ target }) => {
        cy.task('log', `   Affected node: ${target.join(', ')}`);
      });
    });
  }
}

