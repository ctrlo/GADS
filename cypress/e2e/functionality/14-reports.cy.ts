import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { goodPassword, goodUser } from "../../support/constants";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import { ICodeLayoutBuilder, ICurvalLayoutBuilder, IDropdownLayoutBuilder, ILayoutBuilder } from "../../support/builders/layout/interfaces";


describe('Test for report builder', () => {
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
    cy.populateTableWithLayouts(table_shortname);
    cy.clearImports(table_shortname);
    cy.bulkImportRecords();
    cy.clearImports(table_shortname);
    cy.logout();
    });

    beforeEach(() => {
        cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/table');
        cy.location("pathname").should("include", "/table");
    });
    
    after(() => {
        cy.deleteAllData("table1");
        cy.purgeAllDeletedData("table1");
        cy.cleanTableOfLayouts("table1");
        cy.clearAllTablePermissions("table1");
        cy.addUserToDefaultGroup("test@example.com", "uncheck");
    });
    
    it("Should check report builder page is accessible", () => {
        cy.visit('http://localhost:3000/table1/data');
        cy.get('a[href="/table1/report"].link--plain').contains('Reports').click();
        cy.get('a.btn.btn-add[href="/table1/report/add"]').click();
        cy.url().should('include', '/table1/report');
    });

    // Rest of the test to follow
});

