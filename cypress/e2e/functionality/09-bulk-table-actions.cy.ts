import "../../support/commands";
import { goodPassword, goodUser } from "../../support/constants";

describe("Bulk record and table action tests", () => {
  const table_shortname = "table1";

  before(() => {
    cy.log("login").login(goodUser, goodPassword);

    // Add user to base group
    cy.log("update user groups").addUserToDefaultGroup("test@example.com", "check");

    // Set required table permissions
    cy.log("setup table permissions");
    const permissionObject:Record<string, boolean> = {};
    ["Bulk import records", "Purge deleted records", "Delete records", "Bulk delete records"].forEach((permissionName) => {
      permissionObject[permissionName] = true;
    });
    cy.setTablePermissionsByShortName(table_shortname, permissionObject);

    // Create layouts
    cy.log("create layouts");
    cy.populateTableWithLayouts("my_table_shortname");

    cy.logout();
  });

  after(() => {
    cy.cleanTableOfLayouts(table_shortname);
    cy.clearAllTablePermissions(table_shortname);
    cy.addUserToDefaultGroup("test@example.com", "uncheck");
  });

  beforeEach(() => {
    cy.login(goodUser, goodPassword);
  });
  
  context('Bulk import tests', () => {
      it("Should show error for invalid file upload during Import", () => {
          cy.visit("http://localhost:3000/table1/data");
          
          //find and check for import pages
          cy.get("button#bulk_actions").click();
          cy.get('a[href="/table1/import/"]').click();
          cy.get("h2.table-header__page-title").should("contain.text", "Import records");
          cy.get('a[href="/table1/import/data/"]').click();
          cy.get("h2.table-header__page-title").should("contain.text", "Upload");
          
          // Upload invalid file
          cy.get('input[type="file"]').selectFile("cypress/fixtures/testfile.html", { force: true });
          cy.contains("Submit").click();
          
          // Check for error message
          cy.get(".alert-danger")
          .should("be.visible")
          .and("contain", "import headings not found in table");
      });
      
      it("Should clear completed imports and verify empty table", () => {
          cy.clearImports(table_shortname);
      });
      
      it("Should import with dry run, then confirm no errors", () => {
          cy.visit("http://localhost:3000/table1/data");
          
          //find and check for import pages
          cy.get("button#bulk_actions").click();
          cy.get('a[href="/table1/import/"]').click();
          cy.get("h2.table-header__page-title").should("contain.text", "Import records");
          cy.get('a[href="/table1/import/data/"]').click();
          cy.get("h2.table-header__page-title").should("contain.text", "Upload");
          
          // Upload csv file and start dryrun
          cy.get('input[type="file"]').selectFile("cypress/fixtures/Import-test-data.csv", { force: true });
          cy.contains("Submit").click();
          cy.get(".alert.alert-success")
          .should("be.visible")
          .and("contain.text", "The file import process has been started");
          
          //No way to check upload progress so wait 5s
          cy.wait(5000);
          
          // Check upload finished without errs
          cy.visit("http://localhost:3000/table1/import/");
          cy.get("a.link--plain").contains("Completed").should("exist");
          cy.get("a.link--plain").contains(/errors:\s*0/);
          cy.get("a.link--plain").contains(/skipped:\s*0/);
          
          // Check no records actually imported (dry run)
          cy.visit("http://localhost:3000/table1/data");
          cy.get("td.dt-empty")
          .should("be.visible")
          .and("contain", "There are no records available");
      });
      
      it("Should perform full bulk Import and check new records exist", () => {
          cy.bulkImportRecords();
      });
      
      it("Should clear completed reports and verify empty state", () => {
          cy.clearImports("table1");
      });
  });
  
  context('Bulk Delete and purge tests', () => {
      it("Should delete all records and verify empty table", () => {
          cy.visit(`http://localhost:3000/${table_shortname}/data`);
              cy.get("button#bulk_actions").click();
          cy.get("a#delete_href")
          .should("be.visible")
          .and("contain", "Delete all records in this view")
          .click();
          
          cy.get("#bulkDelete").should("be.visible");
          cy.get('button[name="modal_delete"]').should("be.visible").click();
          
          // Check table is empty
          cy.get("td.dt-empty")
          .should("be.visible")
          .and("contain", "There are no records available");
      });
      
      it("Should purge all deleted records", () => {
          cy.purgeAllDeletedData(table_shortname);
      });
  });
});
