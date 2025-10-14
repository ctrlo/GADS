import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import {
  ICodeLayoutBuilder,
  ICurvalLayoutBuilder,
  IDropdownLayoutBuilder,
  ILayoutBuilder,
} from "../../support/builders/layout/interfaces";
import { goodPassword, goodUser } from "../../support/constants";

describe("Layout creation tests", () => {
  const refShortName = "tr";
  const table_shortname = "table1";

  before(() => {
    cy.login(goodUser, goodPassword);
    cy.log("update user groups").addUserToDefaultGroup("test@example.com", "check");
    cy.logout();
  });

  beforeEach(() => {
    cy.login(goodUser, goodPassword);
  });
  
  after(() => {
    // Clear permissions and reset user group
    cy.clearAllTablePermissions("table1");
    cy.addUserToDefaultGroup("test@example.com", "uncheck");
  });


  // Set individual table permissions
  context("Set individual permissions", () => {
    [
      "Bulk import record",
      "Purge deleted records",
      "Download records",
      "Delete records",
      "Bulk update records",
      "Bulk delete records",
      "Manage linked records",
      "Manage child records",
      "Manage views",
      "Manage group views",
      "Select extra view limits",
      "Manage fields",
      "Send messages",
    ].forEach((permissionName) => {
      it(`should set ${permissionName} for table: ${table_shortname}`, () => {
        cy.setTablePermissionsByShortName(table_shortname, {
          [permissionName]: true,
        });
      });
    });
  });

  // Check Manage Views dropdown visibility and options
  context("Check view options are available", () => {
    it("should navigate to data page and click the Manage views dropdown", () => {
      cy.visit(`http://localhost:3000/${table_shortname}/data`);

      cy.get("button#manage_views")
        .should("be.visible")
        .and("contain", "Manage views")
        .click();

      cy.get(".dropdown__list").first().within(() => {
        cy.contains("a", "Add a view").should("be.visible");
        cy.contains("a", "Manage views of another user").should("be.visible");
        cy.contains("a", "Historic view").should("be.visible");
      });
    });
  });

  // Check Actions dropdown visibility and options
  context("Check view options are available", () => {
    it("should navigate to data page and click the Actions dropdown", () => {
      cy.visit(`http://localhost:3000/${table_shortname}/data`);

      cy.get("span")
        .contains("Actions")
        .should("be.visible")
        .click();

      cy.get('.dropdown-menu.dropdown__menu.show .dropdown__list').within(() => {
          
          //commented out the following because they require records in the table to appear 
          //cy.contains("a", "Download records").should("be.visible");
          //cy.contains("a", "Field Data Purge").should("be.visible");
          
          //know issue: purge options dont display unless there is live records in the table 
          //cy.contains("a", "Field Data Purge").should("be.visible");
          //cy.contains("a", "Manage deleted records").should("be.visible");

          cy.contains('a', 'Import records').should('be.visible');
          cy.contains('a', 'Delete all records in this view').should('be.visible');
          cy.contains("a", "Update all records in this view").should("be.visible");
          cy.contains("a", "Clone all records in this view").should("be.visible");
      });
    });
  });

  // Ensure related endpoints load successfully
  context("Check related endpoints are accessible", () => {
    const urls = [
      `/historic_purge/`,
      `/purge/`,
      `/bulk/clone/`,
      `/bulk/update/`,
      `/import/`,
      `/view/0`,
    ];

    urls.forEach((path) => {
      it(`should successfully load ${path}`, () => {
        cy.visit(`http://localhost:3000/${table_shortname}${path}`);

        // Basic sanity check: body exists and is not empty
        cy.get("body").should("exist").and("not.be.empty");
      });
    });
  });

  // Clear permissions
  context("Clear all table permissions", () => {
    it(`Should clear all permissions for ${table_shortname}`, () => {
      cy.clearAllTablePermissions(table_shortname);
    });
  });

  // Verify that restricted UI elements are gone
  context("Ensure both dropdown lists are no longer present", () => {
    it("Ensure the Actions dropdown does not exist on the page", () => {
      cy.visit(`http://localhost:3000/${table_shortname}/data`);

      cy.get("span")
        .contains("Actions")
        .should("not.exist");
    });

    it("Ensure the manage views dropdown does not exist on the page", () => {
      cy.visit(`http://localhost:3000/${table_shortname}/data`);

      cy.get("span")
        .contains("manage_views")
        .should("not.exist");
    });
  });

  // Check endpoints after permissions are cleared
  context("Check restricted endpoints show permission error", () => {
    const urls = [
      `/historic_purge/`,
      `/purge/`,
      `/bulk/clone/`,
      `/bulk/update/`,
      `/import/`,
      // `/view/0`,
    ];

    urls.forEach((path) => {
      it(`should block access to ${path}`, () => {
        cy.visit(`http://localhost:3000/${table_shortname}${path}`, {
          failOnStatusCode: false,
        });

        cy.get('div.alert.alert-danger[role="alert"]')
          .should("be.visible")
          .and("contain.text", "You do not have permission to");
      });
    });
  });
});

