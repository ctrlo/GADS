import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { goodPassword, goodUser } from "../../support/constants";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import { ICodeLayoutBuilder } from "../../support/builders/layout/interfaces";


describe('Edit table feature tests', () => {
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
    
    const builder: ICodeLayoutBuilder = LayoutBuilder.create("RAG") as ICodeLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .withCode(LUA`function evaluate(txt_fd)
                          return "red";
                          end
                          `);
        
        cy.createLayout(builder, true);
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
        cy.deleteLayoutByShortName("t1", true);
        cy.cleanTableOfLayouts("table1");
        cy.clearAllTablePermissions("table1");
        cy.addUserToDefaultGroup("test@example.com", "uncheck");
    });
    
    context('Tests editing table shortname', () => {
        it('error invalid table shortnames', () => {
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('input#name_short').click().clear().type('test/');
            cy.contains('button', 'Save').click();
            cy.location("pathname").should("include", "/table1");
            cy.get('.alert.alert-danger').should('be.visible').and('contain.text', 'Invalid short name')
            
            cy.get('input#name_short').click().clear().type('test%');
            cy.contains('button', 'Save').click();
            cy.location("pathname").should("include", "/table1");
            cy.get('.alert.alert-danger').should('be.visible').and('contain.text', 'Invalid short name')
            
            cy.get('input#name_short').click().clear().type('test test');
            cy.contains('button', 'Save').click();
            cy.location("pathname").should("include", "/table1");
            cy.get('.alert.alert-danger').should('be.visible').and('contain.text', 'Invalid short name')

            // Known Issue: shouldn't allow existing keywords but does so test commented out.
            //cy.get('input#name_short').click().clear().type('myaccount');
            //cy.contains('button', 'Save').click();
            //cy.location("pathname").should("include", "/table1");
            //cy.get('.alert.alert-danger').should('be.visible').and('contain.text', 'Invalid short name')

            cy.get('input#name_short').click().clear().type('THIS_IS_A_VERY_LONG_SHORTNAME_AND_ALTHOUGH_ON_THE_SURFACE_THIS_IS_PROBABLY_NOT_GOING_TO_CAUSE_ANY_ISSUES_IT_SHOULD_STILL_BE_RESTRICTED_TO_FIXED_SIZE_IN_ORDER_TO_PREVENT_ANY_UNEXPECTED_BEHAVIOIR_IN_THE_FUTURE');
            cy.contains('button', 'Save').click();
            cy.location("pathname").should("include", "/table1");
            //Currently a Panic error.
            //cy.get('.alert.alert-danger').should('be.visible').and('contain.text', 'Invalid short name')
            });
            
        it('Should save a valid shortname', () => {
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('input#name_short').click().clear().type('Finally_A_Normal_Name');
            cy.contains('button', 'Save').click();
            cy.location("pathname").should("include", "/Finally_A_Normal_Name");
            cy.get('.alert.alert-success').should('be.visible').and('contain.text', 'The table has been updated successfully')

            cy.get('input#name_short').click().clear();
            cy.contains('button', 'Save').click();
            cy.location("pathname").should("include", "/table1");
            cy.get('.alert.alert-success').should('be.visible').and('contain.text', 'The table has been updated successfully')
        });
    });
    
    context('Tests editing table sort order', () => {
        it('add and edit sorting', () => {
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('#btn-sort_type').click()

            cy.get('#btn-sort_layout_id').click();
            cy.get('li.select__menu-item')
            .contains('Serial').click()
            cy.get('#btn-sort_type').click()
            .get('li.select__menu-item[role="option"][data-value="desc"]').contains('Descending').click();
            cy.contains('button', 'Save').click();
            cy.visit('http://localhost:3000/table1/data');
            cy.get('td.sorting_1').then($cells => {
                const firstFive = [...$cells].slice(0, 5).map(cell => parseInt(cell.innerText.trim(), 10));
                const sortedDesc = [...firstFive].sort((a, b) => b - a);
                expect(firstFive).to.deep.equal(sortedDesc);
            });

            cy.clearLocalStorage();
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('#btn-sort_type').click()
            .get('li.select__menu-item[role="option"][data-value="asc"]').contains('Ascending').click();
            cy.contains('button', 'Save').click();
            cy.visit('http://localhost:3000/table1/data');
            cy.get('td.sorting_1').then($cells => {
                const firstFive = [...$cells].slice(0, 5).map(cell => parseInt(cell.innerText.trim(), 10));
                const sortedAsc = [...firstFive].sort((a, b) => a - b);
                expect(firstFive).to.deep.equal(sortedAsc);
            });

            //Set back to defaults
            cy.visit('http://localhost:3000/table1/edit'); 
            cy.get('#btn-sort_layout_id').click();
            cy.get('li.select__menu-item')
            .contains('Select default sort').click()
            cy.get('#btn-sort_type').click()
            cy.get('li.select__menu-item[role="option"][data-value=""]').contains('Select default sort direction').click();
            cy.contains('button', 'Save').click();
        });
    });

    context('Tests editing table RAG labels', () => {
        it('Should update RAG values', () => {
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('[data-target="#ragFieldDefinitions"]').first().click();

            cy.get('fieldset[data-name="ragFieldDefinitionOptions"] input[type="checkbox"]')
            .each(($el) => {
                cy.wrap($el).check({ force: true }).should('be.checked');
            });
            
            const dangerVal = "!$_ %&*+";
            const warningVal = "<!--"; 
            const advisoryVal = "''''''";
            const successVal = "../../../";
            const completeVal = "</a>";
            const undefinedVal = "As always I wouldn't expect anyone to ever type an essay this long withing a RAG value but you never know. Therefore, I have written this test to check that something of this size is handled correctly and will not break our table :)";
            const unexpectedVal = "Normal value";

            cy.get('#danger_description').clear().type(dangerVal);
            cy.get('#warning_description').clear().type(warningVal);
            cy.get('#advisory_description').clear().type(advisoryVal);
            cy.get('#success_description').clear().type(successVal);
            cy.get('#complete_description').clear().type(completeVal);
            cy.get('#undefined_description').clear().type(undefinedVal);
            cy.get('#unexpected_description').clear().type(unexpectedVal);
            cy.contains('button', 'Save').click();

            cy.visit('http://localhost:3000/table1/data');
            cy.get('#rag_danger_meaning').should('contain.text', dangerVal);
            cy.get('#rag_warning_meaning').should('contain.text', warningVal);
            cy.get('#rag_advisory_meaning').should('contain.text', advisoryVal);
            cy.get('#rag_success_meaning').should('contain.text', successVal);
            cy.get('#rag_complete_meaning').should('contain.text', completeVal);
            cy.get('#rag_undefined_meaning').should('contain.text', undefinedVal);
            cy.get('#rag_unexpected_meaning').should('contain.text', unexpectedVal);

            //Hide RAG labels
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('[data-target="#ragFieldDefinitions"]').first().click();

            cy.get('fieldset[data-name="ragFieldDefinitionOptions"] input[type="checkbox"]')
            .each(($el) => {
                cy.wrap($el).uncheck({ force: true }).should('not.be.checked');
            });
            cy.contains('button', 'Save').click();
      
            cy.visit('http://localhost:3000/table1/data');
            cy.get('#rag_danger_meaning').should('not.exist');
            cy.get('#rag_attention_meaning').should('not.exist');
            cy.get('#rag_warning_meaning').should('not.exist');
            cy.get('#rag_advisory_meaning').should('not.exist');
            cy.get('#rag_success_meaning').should('not.exist');
            cy.get('#rag_complete_meaning').should('not.exist');
            cy.get('#rag_undefined_meaning').should('not.exist');
            cy.get('#rag_unexpected_meaning').should('not.exist');

            //Return RAG labels back to default vals
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('[data-target="#ragFieldDefinitions"]').first().click();

            cy.get('fieldset[data-name="ragFieldDefinitionOptions"] input[type="checkbox"]')
            .each(($el) => {
                cy.wrap($el).check({ force: true }).should('be.checked');
            });

            cy.get('#danger_description').clear().type("danger");
            cy.get('#warning_description').clear().type("warning");
            cy.get('#advisory_description').clear().type("advisory");
            cy.get('#success_description').clear().type("success");
            cy.get('#complete_description').clear().type("complete")
            cy.get('#undefined_description').clear().type("undefined");
            cy.get('#unexpected_description').clear().type("unexpected");
            cy.contains('button', 'Save').click();

            cy.visit('http://localhost:3000/table1/data');
            cy.get('#rag_danger_meaning').should('contain.text', "danger");
            cy.get('#rag_warning_meaning').should('contain.text', "warning");
            cy.get('#rag_advisory_meaning').should('contain.text', "advisory");
            cy.get('#rag_success_meaning').should('contain.text', "success");
            cy.get('#rag_complete_meaning').should('contain.text', "complete");
            cy.get('#rag_undefined_meaning').should('contain.text', "undefined");
            cy.get('#rag_unexpected_meaning').should('contain.text', "unexpected");
        });
    });
    context('Tests setting a table permission view ', () => {
        it('apply permission view to table and check access', () => {
            //Create 2 views. One admin to limit access one for all data
            cy.log("Creating permission view")
            cy.visit('http://localhost:3000/table1/data')
            .get("span").contains("Manage views").click()
            .get('a[role="menuitem"]').contains("Add a view").click()
            .get('input[name="name"]').type("Permission view")
            .get('input#is_admin').check({ force: true }).should('be.checked')
            .get("span").contains("Filter").click()
            .get("button").contains("Add rule").click()
            .get("div.filter-option-inner-inner").contains("------").click()
            .get(".dropdown-menu.show").last()
            .find('a[role="option"]').not('[aria-hidden="true"]').contains("ID").click()
            .get('input.form-control[type="text"]').last().type("0");
            cy.get('button[type="submit"]').contains("Save").click();
            cy.contains("Showing 0 to 0 of 0 entries").should("be.visible");
        
            //Apply permission view to table
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('[data-target="#limitRecordAccess"]').first().click();
            cy.get('#btn-view_limit_id').click();
            cy.get('li.select__menu-item').contains('Permission view').click();
            cy.contains('button', 'Save').click();
            cy.visit('http://localhost:3000/table1/data');
            cy.contains("Showing 0 to 0 of 0 entries").should("be.visible");

            //Attempt to delete permission view while its applied
            cy.visit('http://localhost:3000/table1/data')
            .get("span").contains("Manage views").click()
            .get('a[role="menuitem"]').contains("Edit current view").click()
            .get(".btn-js-delete").contains("Delete view").click()
            .get('button[type="submit"]').contains("Delete").click();
            cy.get('div.alert.alert-danger').should('be.visible');    //currently this panics need err handling

            //Create all records personal view
            cy.log("Creating all data view")
            cy.visit('http://localhost:3000/table1/data')
            .get("span").contains("Manage views").click()
            .get('a[role="menuitem"]').contains("Add a view").click()
            .get('input[name="name"]').type("All record view")
            cy.contains('button', 'Save').click();
            //Check All view shows no records
            cy.visit('http://localhost:3000/table1/data');
            cy.contains("Showing 0 to 0 of 0 entries").should("be.visible");
            cy.contains("span", "Current view: All record view").should("exist");

            //Now take table permission view off
            cy.visit('http://localhost:3000/table1/edit');
            cy.get('[data-target="#limitRecordAccess"]').first().click();
            cy.get('#btn-view_limit_id').click();
            cy.get('li.select__menu-item').contains('All record view').should('not.exist');    //check the  personal view is not in the list.
            cy.get('li.select__menu-item').contains('All data').click();
            cy.contains('button', 'Save').click();

            //Checks the same all records view now shows records.
            cy.visit('http://localhost:3000/table1/data');
            cy.contains("span", "Current view: All record view").should("exist");
            cy.contains("Showing 1 to").should("be.visible");
            cy.deleteAllViewsForTable(table_shortname);
        });
    });
});
