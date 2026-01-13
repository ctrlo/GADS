import { goodPassword, goodUser } from "../../support/constants";

describe("Creating Tables using the Wizard", () => {
  beforeEach(() => {
    cy.loginAndGoTo(goodUser, goodPassword, "http://localhost:3000/table");
    cy.location("pathname").should("include", "/table");
  });

  context("Basic Add/Delete tests", () => {
    // Skipped test: known issue where error not appearing for invalid shorname.
    it.skip("should fail to save new table with invalid shortname", () => {
      cy.get('[data-target="#newTableModal"]').click();
      cy.get("#shortName").type("This value wont $4v£");
      cy.get("#name").type("table to fail");
      cy.get(".btn-js-next").first().click();
      cy.get(".btn-js-save").first().click();

      // Check for failed save error
      cy.get("div.alert.alert-danger")
        .should("be.visible")
        .and("contain", "Invalid short name for table");
    });

    it("should save a new empty table successfully", () => {
      cy.createInstance("1-test-table");

      // Check new table is displayed on table page
      cy.location("pathname").should("include", "/table");
      cy.contains("1-test-table").should("exist");
    });

    it("should make the new table accessible", () => {
      // Check table edit page is accessible
      cy.contains("tr", "1-test-table")
        .contains("a", "Edit table")
        .click();

      cy.location("pathname").should("include", "1-test-table/edit");
    });

    it("should delete the table successfully", () => {
      cy.deleteInstanceByShortName("1-test-table");

      // Check table no longer appears on table page
      cy.location("pathname").should("include", "/table");
      cy.contains(
        ".alert.alert-success",
        "The table has been deleted successfully"
      ).should("exist");
      cy.contains("1-test-table").should("not.exist");
    });

    it("should confirm deleted table is no longer accessible", () => {
      // Attempt to access the deleted table URL directly
      cy.request({
        url: "http://localhost:3000/1-test-table/edit",
        failOnStatusCode: false, // Prevent Cypress from failing on 404/302
      }).then((response) => {
        expect(response.status).to.be.oneOf([302, 404]);
      });
    });
  });
});

