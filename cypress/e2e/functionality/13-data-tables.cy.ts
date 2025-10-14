import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { goodPassword, goodUser } from "../../support/constants";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import { ICodeLayoutBuilder, ICurvalLayoutBuilder, IDropdownLayoutBuilder, ILayoutBuilder } from "../../support/builders/layout/interfaces";


describe('Test data table features', () => {
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
   // cy.addUserToDefaultGroup('test@example.com');
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

    //function to run table search multiple times
    function searchTests() {
        //paritial string value
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        cy.get('input[type="search"]').click().type('RECORD 5');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', 'RECORD 5');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        
        //test clear
        cy.get('input[type="search"]').click().clear();
        cy.get('#DataTables_Table_0_info').should('not.have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);

        //Full string value
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        cy.get('input[type="search"]').click().type('RECORD 5 \\<');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', 'RECORD 5 \\<');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('input[type="search"]').click().clear();
        
        //partial date range val
        //cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        //cy.get('input[type="search"]').click().clear().type('2024-04')
        //cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', '2024-04');
        //cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        
        //Full date value match
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        cy.get('input[type="search"]').click().type('2024-04-04');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', '2024-04-04');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('input[type="search"]').click().clear();

        //parital integer value
        //cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        //cy.get('input[type="search"]').click().type('77777')
        //cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', '77777');
        //cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        //cy.get('input[type="search"]').click().clear()

        //Full integer value
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        cy.get('input[type="search"]').click().type('7777777');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', '7777777');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('input[type="search"]').click().clear();

        //parital date range value
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        cy.get('input[type="search"]').click().type('to 2017-');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', 'to 2017-');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('input[type="search"]').click().clear();

        //Full date range value
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        cy.get('input[type="search"]').click().type('2007-07-07 to 2017-07-17');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', '2007-07-07 to 2017-07-17');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('input[type="search"]').click().clear();
    }
    
    //function to run col sorts  multiple times
    function columnSorts() {
        cy.get('span.dt-column-title[role="button"]').contains('Number Field').click();
        cy.get('span.dt-column-title[role="button"]').contains('Number Field').click();
        
        //wait for loading icon to appear then disappear
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('be.visible');
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('not.be.visible');

        cy.get('td.sorting_1').then($cells => {
            const firstFive = [...$cells].slice(0, 5).map(cell => parseInt(cell.innerText.trim(), 10));
            const sortedDesc = [...firstFive].sort((a, b) => b - a);
            expect(firstFive).to.deep.equal(sortedDesc);
        });
        cy.get('span.dt-column-title[role="button"]').contains('Number Field').click();
        //cy.contains('span.dt-column-title[role="button"]', 'Number Field').click();
        
        //wait for loading icon to appear then disappear
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('be.visible');
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('not.be.visible');

        cy.get('td.sorting_1').then($cells => {
            const firstFive = [...$cells].slice(0, 5).map(cell => parseInt(cell.innerText.trim(), 10));
            const sortedAsc = [...firstFive].sort((a, b) => a - b);
            expect(firstFive).to.deep.equal(sortedAsc);
        });
    }
    
    //function to run col searches multiple times
    function columnSearch() {
        //work around to find the search by header by name
        cy.get('th:visible')
        .filter((i, el) => el.innerText.includes('Text Field'))
        .first()
        .within(() => {
            cy.get('button.btn-search.dropdown-toggle').click({ force: true });
            cy.get('div.dropdown-menu input[type="text"]').type('RECORD 1', { force: true });
        });
        cy.contains('label', 'Rows per page').click();
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length', 1).and('contain.text', 'RECORD 1');
        cy.get('#DataTables_Table_0_info').should('have.text', 'Showing 1 to 1 of 1 entry');
        // clear the column search
        cy.get('th:visible')
        .filter((i, el) => el.innerText.includes('Text Field'))
        .first()
        .within(() => {
            cy.get('button.btn-search.dropdown-toggle').click({ force: true });
            cy.get('.dropdown-menu.p-2.show')
            .find('button.data-table__clear')
            .contains('Clear filter')
            .click({ force: true });
        });
        cy.get('#DataTables_Table_0_info').should('not.have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
        
        //work around to find the search by header by name
        cy.get('th:visible')
        .filter((i, el) => el.innerText.includes('Dropdown Field'))
        .first()
        .within(() => {
        cy.get('button.btn-search.dropdown-toggle').click({ force: true });
        cy.get('div.dropdown-menu input[type="text"]').type('Bl', { force: true });
        });
        cy.get('div.tt-suggestion').contains('Blue').click();
        cy.contains('label', 'Rows per page').click();
        //wait for loading icon to appear then disappear
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('be.visible');
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('not.be.visible');

        cy.get('table#DataTables_Table_0 tbody tr').each($row => {
            const text = $row.text();
            expect(text).to.include('Blue');
            expect(text).not.to.include('Red');
        });
        // clear the column search
        cy.get('th:visible')
        .filter((i, el) => el.innerText.includes('Dropdown Field'))
        .first()
        .within(() => {
            cy.get('button.btn-search.dropdown-toggle').click({ force: true });
            cy.get('.dropdown-menu.p-2.show')
            .find('button.data-table__clear')
            .contains('Clear filter')
            .click({ force: true });
        });
        //check clear worked
        cy.get('#DataTables_Table_0_info').should('not.have.text', 'Showing 1 to 1 of 1 entry');
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 1);
    }

    it("Should check and test table search", () => {
        cy.visit('http://localhost:3000/table1/data');
        searchTests();
    });
    
    it("Should check and test column sort", () => {
        cy.visit('http://localhost:3000/table1/data?table_clear_state=1');
        columnSorts();
    });
    
    it("Should check and test column searches", () => {
        cy.visit('http://localhost:3000/table1/data');
        columnSearch();
    });

    it("Should check and test fullscreen", () => {
        cy.visit('http://localhost:3000/table1/data?table_clear_state=1');

        //wait for loading icon to appear then disappear
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('be.visible');
        cy.get('#DataTables_Table_0_processing', { timeout: 10000 }).should('not.be.visible');

        cy.get('#table-modal').should('not.exist');
        cy.get('#full-screen-btn').click();
        cy.get('#table-modal')
        .should('have.class', 'data-table__container--scrollable')
        columnSorts();
        columnSearch();
        searchTests();
        cy.get('#full-screen-btn').click();
        cy.get('#table-modal').should('not.exist');
    });

    it("Should check historic view", () => {
        cy.visit('http://localhost:3000/table1/data');
        cy.get('button#manage_views').should('be.visible').and('contain', 'Manage views').click();
        cy.contains('a', 'Historic view').should('be.visible').click();
        cy.get('input#rewind_date').clear().type('1999-09-19');
        cy.get('#rewind_time').clear().type('09:09:09');
        cy.get('button[name="modal_rewind"][type="submit"]').click();
        cy.get('div[role="alert"].alert-info').should('be.visible').and('contain.text', 'You are viewing data as it was on 1999-09-19 at 09:09:09');
        cy.contains("Showing 0 to 0 of 0 entries").should("be.visible");

        //Clear the view
        cy.get('button#manage_views').should('be.visible').and('contain', 'Manage views').click();
        cy.contains('a', 'Historic view').should('be.visible').click();
        cy.get('button[type="submit"][name="modal_rewind_reset"][value="submit"]').contains('Reset to normal').click();
        cy.get('table#DataTables_Table_0 tbody tr').should('have.length.greaterThan', 0).and('not.contain.text', 'There are no records available');
    });
});

