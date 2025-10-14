import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import {
  ICodeLayoutBuilder,
  ICurvalLayoutBuilder,
  IDropdownLayoutBuilder,
  ILayoutBuilder
} from "../../support/builders/layout/interfaces";
import { goodPassword, goodUser } from "../../support/constants";

describe("Record create/edit tests", () => {
    const table_shortname = "table1";
    
    before(() => {
        cy.log("login").login(goodUser, goodPassword);
        cy.log("update user groups").addUserToDefaultGroup("test@example.com", "check");
        cy.log("setup table permissions");
        
        const permissionObject: Record<string, boolean> = {};
        [
            "Purge deleted records",
            "Delete records",
            "Bulk delete records",
            "Manage views"
        ].forEach((permissionName) => {
            permissionObject[permissionName] = true;
        });
        cy.setTablePermissionsByShortName(table_shortname, permissionObject);
        cy.addUserToDefaultGroup('test@example.com');
        cy.populateTableWithLayouts("my_table_shortname");
        cy.logout();
    });
    
    beforeEach(() => {
        cy.login(goodUser, goodPassword);
        cy.gotoInstanceByShortName("table1", "data");
    });
    
    after(() => {
        cy.deleteAllData("table1");
        cy.purgeAllDeletedData("table1");
        cy.cleanTableOfLayouts("table1");
        cy.clearAllTablePermissions("table1");
        cy.addUserToDefaultGroup("test@example.com", "uncheck");
    });
    
    it("It should create a record", () => {
        cy.contains('a', 'Add a record').click();
        //Add a value to all text fields
        cy.get('input[type="text"]:not([data-dateformat-datepicker])')
        .each(($input) => {
            cy.wrap($input).clear().type('Hello Test');
        });
        
        //Add a value to all dates and dateranges
        const dateStr = '2222-01-30';
        cy.get('input[data-dateformat-datepicker]')
        .each(($input) => {
            cy.wrap($input)
            .focus()
            .type(dateStr, { force: true })
            .blur();
        });
        //Select the first available option in all dropdowns field
        cy.get('.linkspace-field[data-column-type="enum"]')
        .each(($dropdown) => {
            cy.wrap($dropdown)
            .find('div.select-widget-dropdown > div.form-control > ul.current')
            .click({ force: true });
            cy.wrap($dropdown)
            .find('ul.available.select__menu.show label').first()
            .then(($label) => {
                const optionText = $label.text().trim();
                cy.wrap($dropdown)
                .find('input.form-control-search').clear()
              .type(optionText, { force: true });
              cy.wrap($dropdown)
              .find('ul.available.select__menu.show')
              .contains('label', optionText)
              .click({ force: true });
            });
        });
        //Add a value to all integer fields
        cy.get('input[type="number"]').each(($input) => {
            cy.wrap($input).clear().type('111');
        });
        cy.get('button#submit').click();
    });
    
    it("It should test for manadatory errors followed by a successful create record", () => {
        cy.contains('a', 'Add a record').click();
        //Get how many inputs are required on this form?
        cy.get('input[required], input[aria-required="true"], textarea[required], textarea[aria-required="true"]')
        .then(($required) => {
            const requiredCount = $required.length;
            cy.log(`Found ${requiredCount} required controls`);
            cy.get('button#submit').click();
            //Same number must now be invalid
            cy.get('input:invalid[required], input[aria-invalid="true"], textarea:invalid[required], textarea[aria-invalid="true"]')
            .should('have.length', requiredCount);
            //Every field should error and should mention "required"
            cy.get('.form-text--error:visible')
            .each(($msg) => {
                cy.wrap($msg).should('contain.text', 'required');
            });
        });
        //Add a value to all text fields
        cy.get('input[type="text"]:not([data-dateformat-datepicker])')
        .each(($input) => {
            cy.wrap($input).clear().type('Hello Test');
        });
        //Add a value to all dates and dateranges
        const dateStr = '2222-01-30';
        cy.get('input[data-dateformat-datepicker]')
        .each(($input) => {
            cy.wrap($input)
            .focus()
            .type(dateStr, { force: true })
            .blur();
        });
        //Select the first available option in all dropdowns fields
        cy.get('.linkspace-field[data-column-type="enum"]')
        .each(($dropdown) => {
            cy.wrap($dropdown)
            .find('div.select-widget-dropdown > div.form-control > ul.current')
            .click({ force: true });
            cy.wrap($dropdown)
            .find('ul.available.select__menu.show label')
            .first()
            .then(($label) => {
                const optionText = $label.text().trim();
                cy.wrap($dropdown)
                .find('input.form-control-search')
                .clear()
                .type(optionText, { force: true });
                cy.wrap($dropdown)
                .find('ul.available.select__menu.show')
                .contains('label', optionText)
                .click({ force: true });
            });
        });
        //Add a value to all integer fields
        cy.get('input[type="number"]').each(($input) => {
            cy.wrap($input).clear().type('111');
        });
        //Save record
        cy.get('button#submit').click();
        cy.get("td.dt-empty").should("not.exist");
        cy.get('div.alert.alert-success[role="alert"]')
        .should('be.visible')
        .and('contain.text', "Submission has been completed successfully")
    });
    
    it("Should show datatype errors and then successfully create a record", () => {
        cy.contains('a', 'Add a record').click();
        cy.get('input[type="text"]:not([data-dateformat-datepicker])')
        .each(($input) => {
            cy.wrap($input).clear().type('hello text');
        });
        
        //Add invalid values to all date and date range inputs
        const invalidDate = '99/99/9999';
        cy.get('input[data-dateformat-datepicker]')
        .each(($input) => {
            cy.wrap($input)
            .focus()
            .type(invalidDate, { force: true })
            .blur();
        });
        
        //Select the first option in all dropdown fields
        cy.get('.linkspace-field[data-column-type="enum"]')
        .each(($dropdown) => {
            cy.wrap($dropdown)
        .find('div.select-widget-dropdown > div.form-control > ul.current')
        .click({ force: true });

      cy.wrap($dropdown)
        .find('ul.available.select__menu.show label')
        .first()
        .then(($label) => {
          const optionText = $label.text().trim();
          cy.wrap($dropdown)
            .find('input.form-control-search')
            .clear()
            .type(optionText, { force: true });

          cy.wrap($dropdown)
            .find('ul.available.select__menu.show')
            .contains('label', optionText)
            .click({ force: true });
        });
    });
    //Change integer field value
    cy.get('input[type="number"]')
    .each(($input) => {
      cy.wrap($input).clear().type('111');
    });
    
    cy.get('button#submit').click();
    cy.get('div.alert.alert-danger[role="alert"]')
    .should('be.visible')
    .and('contain.text', "Invalid date");

    //Change the date field value
    const validDate = '2222-01-30';
    cy.get('input[data-dateformat-datepicker]')
    .each(($input) => {
      cy.wrap($input)
        .clear()
        .focus()
        .type(validDate, { force: true })
        .blur();
    });
    
    cy.get('button#submit').click();
    cy.get("td.dt-empty").should("not.exist");
    cy.get('div.alert.alert-success[role="alert"]').should('be.visible').and('contain.text', "Submission has been completed successfully");
  });
  
  it("Should create/edit draft followed by a save", () => {
      cy.contains('a', 'Add a record').click();
      //Add a value to all text fields
      cy.get('input[type="text"]:not([data-dateformat-datepicker])')
      .each(($input) => {
          cy.wrap($input).clear().type('Hello Test');
      });
      //Save as draft
      cy.get('button#save-draft').click();
      cy.get('div.alert.alert-success[role="alert"]')
      .should('be.visible')
      .and('contain.text', 'NOTICE:')
      .and('contain.text', 'Draft has been saved successfully');

      cy.contains('a.btn.btn-add', 'Continue draft record').should('be.visible').click();

      cy.get('input[type="text"][value="Hello Test"]:not([data-dateformat-datepicker])').should('exist');
      cy.get('button#delete_draft').click();

      cy.get('div.alert.alert-success[role="alert"]')
      .should('be.visible').and('contain.text', 'NOTICE:').and('contain.text', 'Draft has been deleted successfully');
      
      cy.contains('a', 'Add a record').click();
      //Add a value to all text fields
      cy.get('input[type="text"]:not([data-dateformat-datepicker])')
      .each(($input) => {
          cy.wrap($input).clear().type('Hello Test');
      });
      //Add a value to all dates and dateranges
      const dateStr = '2222-01-30';
      cy.get('input[data-dateformat-datepicker]')
      .each(($input) => {
          cy.wrap($input)
          .focus()
          .type(dateStr, { force: true })
          .blur();
      });
      //select the first available option in all dropdowns field
      cy.get('.linkspace-field[data-column-type="enum"]')
      .each(($dropdown) => {
          cy.wrap($dropdown)
          .find('div.select-widget-dropdown > div.form-control > ul.current')
          .click({ force: true });
          cy.wrap($dropdown)
          .find('ul.available.select__menu.show label')
          .first()
          .then(($label) => {
              const optionText = $label.text().trim();
              cy.wrap($dropdown)
              .find('input.form-control-search')
              .clear()
              .type(optionText, { force: true });
              cy.wrap($dropdown)
              .find('ul.available.select__menu.show')
              .contains('label', optionText)
              .click({ force: true });
          });
      });
      //Add a value to all integer fields
      cy.get('input[type="number"]').each(($input) => {
          cy.wrap($input).clear().type('111');
      });
      //Save record as draft
      cy.get('button#save-draft').click();
      cy.get('div.alert.alert-success[role="alert"]')
      .should('be.visible')
      .and('contain.text', 'NOTICE:')
      .and('contain.text', 'Draft has been saved successfully');

      cy.contains('a.btn.btn-add', 'Continue draft record')
      .should('be.visible')
      .click();
      
      //Save draft as record
      cy.get('button#submit').click();
      cy.get("td.dt-empty").should("not.exist");
      cy.get('div.alert.alert-success[role="alert"]')
      .should('be.visible')
      .and('contain.text', "Submission has been completed successfully");
  });
  
  it("It should create a record from a duplicate", () => {

  cy.get('table tbody tr').first().click();
  cy.contains('li.list__item a', 'Duplicate record').click();

  //Ensure the URL includes clone param 'from='
  cy.url().should('include', 'from=');

  //Check for copied values
  cy.get('input[type="text"]').should('have.value', 'Hello Test');
  cy.get('input[type="number"]').should('have.value', '111');
  cy.get('input[data-dateformat-datepicker]').should('have.value', '2222-01-30');
  cy.get('button#submit').click();
  cy.get('.alert.alert-success')
  .should('be.visible')
  .and('contain.text', 'Submission has been completed successfully');
});

});
