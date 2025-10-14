import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import { ICodeLayoutBuilder, ICurvalLayoutBuilder, IDropdownLayoutBuilder, ILayoutBuilder } from "../../support/builders/layout/interfaces";
import { goodPassword, goodUser } from "../../support/constants";

describe("Ceate/edit curvals", () => {
    const table_shortname = "table1";
    const parent_tbl = "parent_table";
 
    before(() => {
        cy.log("login").login(goodUser, goodPassword);
        cy.log("update user groups").addUserToDefaultGroup("test@example.com", "check");
        cy.log("create curval table");
        cy.populateTableWithLayouts("my_table_shortname");
        cy.createInstance(parent_tbl)
        cy.gotoInstanceByShortName(parent_tbl, "layout")

        // Create curval field with reference to reference field
        const builder: ICurvalLayoutBuilder = LayoutBuilder.create("CURVAL") as ICurvalLayoutBuilder;
        builder
            .withName("CURVAL FIELD TEST")
            .withShortName("curval_shortname")
            .withReference("WebDriverTestSheet")
            .withField("Text Field");
            // Check the field exists and doesn't error
            cy.createLayout(builder);
            builder.checkField();
            
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
            cy.setTablePermissionsByShortName(parent_tbl, permissionObject);
            cy.clearImports(table_shortname);
            cy.bulkImportRecords();
            cy.clearImports(table_shortname);
    });
    
    after(() => {
        cy.deleteAllData(parent_tbl);
        cy.purgeAllDeletedData(parent_tbl);
        cy.gotoInstanceByShortName(parent_tbl, "layout");
        cy.deleteLayoutByShortName("curval_shortname");
        cy.deleteInstanceByShortName(parent_tbl);

        cy.deleteAllData("table1");
        cy.purgeAllDeletedData("table1");
        cy.cleanTableOfLayouts("table1");
        cy.clearAllTablePermissions("table1");
        cy.addUserToDefaultGroup("test@example.com", "uncheck");
        cy.logout();
    });
    
    it("Create a record in curval table and select it", () => {
        cy.gotoInstanceByShortName(parent_tbl, "data");

        cy.contains('a', 'Add a record').click();

        cy.contains('fieldset', 'CURVAL FIELD TEST').within(() => {
            // Open the dropdown
            cy.contains('li.none-selected', 'Select option').click();

            // Make sure multiple options exist
            cy.get('ul.select__menu li.answer:visible')
            .should('have.length.greaterThan', 1);

            // Search for curval and select it
            cy.get('input[placeholder="Search..."]')
            .should('be.visible')
            .type('RECORD 1');

            cy.get('ul.select__menu li.answer:visible')
            .contains('RECORD 1')
            .click({ force: true });

            cy.get('.select-widget--required .current li')
            .should('contain.text', 'RECORD 1  HELLO');
        });
        
        cy.get('button#submit').click();
        cy.get("td.dt-empty").should("not.exist");
        cy.get('div.alert.alert-success[role="alert"]')
        .should('be.visible')
        .and('contain.text', "Submission has been completed successfully");
    });
    
    it("Change curval type to auto selector and save a record", () => {

        // Edit curval
        cy.log("login").login(goodUser, goodPassword);
        cy.gotoInstanceByShortName(parent_tbl, "layout");
        cy.contains('td a', 'curval_shortname').click();
        cy.get("button").contains("Field settings for fields from another table").click();

        cy.get('#btn-value_selector').click();
        cy.get('body').contains('li', 'Auto-complete textbox').click({ force: true });

        // Work around for the empty condition bug remove when fixed
        cy.get('.rules-group-body').find('button[data-delete="rule"]').first().click();

        cy.get('#submit_save').click();


        cy.gotoInstanceByShortName(parent_tbl, "data");

        cy.contains('a', 'Add a record').click();

        cy.contains('fieldset', 'CURVAL FIELD TEST').within(() => {
            // Open the search
            cy.contains('li.none-selected', 'Select option').click();

            cy.get('ul.available.select__menu.dropdown-menu.show.with-details li').not('.spinner, .has-noresults').should('have.length', 0);

            // Search for curval and select it
            cy.get('input[placeholder="Search..."]')
            .should('be.visible')
            .type('RECORD 1');

            cy.get('ul.select__menu li.answer:visible')
            .contains('RECORD 1')
            .click({ force: true });

            cy.get('.select-widget--required .current li')
            .should('contain.text', 'RECORD 1  HELLO');
        });

        cy.get('button#submit').click();
        cy.get("td.dt-empty").should("not.exist");
        cy.get('div.alert.alert-success[role="alert"]')
        .should('be.visible')
        .and('contain.text', "Submission has been completed successfully");
    });
    
    it("Change curval type to multi val no selector and save a record", () => {
        // Edit curval
        cy.log("login").login(goodUser, goodPassword);
        cy.gotoInstanceByShortName(parent_tbl, "layout");
        cy.contains('td a', 'curval_shortname').click();
        cy.get("button").contains("Field settings for fields from another table").click();

        cy.get('#btn-value_selector').click();
        cy.get('body').contains('li', 'Do not show selector').click({ force: true });

        // Check the add records option.
        cy.get('input[name="show_add"]').check({ force: true }).should('be.checked');

        // Check the Allow multiple values  option.
        cy.get("button").contains("Advanced settings").click();
        cy.get('input[name="multivalue"]').check({ force: true }).should('be.checked');


        cy.get('#submit_save').click();

        cy.gotoInstanceByShortName(parent_tbl, "data");
        // Wait until the loader disappears
        cy.get('#DataTables_Table_0_processing').should('not.be.visible');
        
        //edit first record
        cy.get('table.data-table tbody tr')
        .first()
        .find('td')
        .eq(0)
        .find('a')
        .click();


        cy.contains('span.btn__title', 'Edit')
        .closest('button')          
        .click();

        //Find click edit on the curval
        cy.contains('legend', 'CURVAL FIELD TEST')  
        cy.get('tbody tr.table-curval-item')
        .first()                            
        .contains('span.btn__title', 'Edit')    
        .closest('button')                         
        .click();

        // Find the Text Field by its label
        cy.contains('label', 'Text Field')
        .parent()
        .siblings('.input__field')
        .find('input')
        .should(($input) => {
            const val = $input.val()
            // Check for original value then change
            expect(val).to.match(/RECORD 1\s+HELLO “ ’/)
        })
        .clear()
        .type('Other Value');

        // Click the Update button inside the same form
        cy.get('.curval-edit-form')
        .find('button.btn-js-submit-record')
        .click();

        cy.get('tr.table-curval-item')
        .contains('td.curval-inner-text', 'Other Value')
        .should('exist');
    });
    
    it("Save multiple curvals  to a record", () => {
        cy.log("login").login(goodUser, goodPassword);
        cy.gotoInstanceByShortName(parent_tbl, "data");
        
        // Wait until the loader disappears
        cy.get('#DataTables_Table_0_processing').should('not.be.visible');
        
        // Edit first record
        cy.get('table.data-table tbody tr') 
        .first()                        
        .find('td')                       
        .eq(0)                          
        .find('a')                        
        .click();

        cy.contains('span.btn__title', 'Edit')
        .closest('button')
        .click();

        cy.get('.btn-add-link').click();

        // Update Text Field
        cy.contains('label', 'Text Field')
        .invoke('attr', 'for')
        .then((id) => {
            cy.get(`input#${id}`).type('1');
        });

        // Update Dropdown Field (choose "Red" as an example)
        cy.contains('legend', 'Dropdown Field')
        .closest('fieldset')                
        .find('input[type="radio"]')        
        .first()
        .check({ force: true });

        // Update Number Field
        cy.contains('label', 'Number Field')
        .invoke('attr', 'for')
        .then((id) => {
            cy.get(`input#${id}`).type('1');
        });

        // Update all Date Fields
              const dateStr = '2222-01-30';
      cy.get('input[data-dateformat-datepicker]')
      .each(($input) => {
          cy.wrap($input)
          .focus()
          .type(dateStr, { force: true })
          .blur();
      });
      
      cy.contains('button.btn-js-submit-record', 'Add').click();
      
      // Check for 2 records
      cy.get('table.data-table tbody tr')
      .its('length')
      .should('be.gt', 1);
      
      // Edit first record
      cy.get('table.data-table tbody tr')
      .first()              
      .find('button.btn-js-curval-modal')
      .click();
      
      // Check Text Field
      cy.contains('label', 'Text Field')
      .closest('.input')
      .find('input')
      .should('have.value', '1');
      
      // Check Number Field
      cy.contains('label', 'Number Field')
      .closest('.input')
      .find('input')
      .should('have.value', '1');
      
      // Check Date Field
      cy.contains('label', 'Date Field')
      .closest('.input')
      .find('input')
      .should('have.value', '2222-01-30');
      
      // Close curval
      cy.contains('button', 'Close').click();
    });
    
    it("Change curval back to dropdown and curval filtering", () => {
        // Edit curval
        cy.log("login").login(goodUser, goodPassword);
        cy.gotoInstanceByShortName(parent_tbl, "layout");
        cy.contains('td a', 'curval_shortname').click();
        cy.get("button").contains("Field settings for fields from another table").click();

        cy.get('#btn-value_selector').click();
        cy.get('body').contains('li', 'Drop-down box').click({ force: true });

        //add curval filter
        cy.get("button").contains("Add rule").click();
        cy.get("div.filter-option-inner-inner").contains("------").click();
        cy.get('ul.dropdown-menu.inner.show a[role="option"]')
        .contains('Text Field')
        .click({ force: true });

        cy.get('div.rule-value-container')
        .find('input.form-control[name="builder1_rule_0_value_0"]')
        .clear()
        .type("RECORD 2 HERE !?!");
        cy.get('#submit_save').click();
        
        // Add the record
        cy.gotoInstanceByShortName(parent_tbl, "data");
        cy.contains('a', 'Add a record').click();

        cy.contains('fieldset', 'CURVAL FIELD TEST').within(() => {
        // Open the dropdown
        cy.contains('li.none-selected', 'Select option').click();

        // Search for RECORD 1,it should NOT exist
        cy.get('input[placeholder="Search..."]').clear().type('RECORD 1');
        cy.get('ul.select__menu li.answer')
        .contains('RECORD 1')
        .should('not.exist');

        // Search for RECORD 2, it should appear
        cy.get('input[placeholder="Search..."]').clear().type('RECORD 2');
        cy.get('ul.select__menu li.answer:visible')
        .should('have.length', 1)
        .contains('RECORD 2')
        .click({ force: true });
        
        cy.get('.select-widget--required .current li')
        .should('contain.text', 'RECORD 2 HERE !?!');
        });

        //save and check the record
        cy.get('button#submit').click();
        cy.get("td.dt-empty").should("not.exist");
        cy.get('div.alert.alert-success[role="alert"]')
        .should('be.visible')
        .and('contain.text', "Submission has been completed successfully");
    });
});
