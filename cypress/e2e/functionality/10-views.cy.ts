import { ViewDefinition } from "../../support/builders/layout/definitions"
import { goodPassword, goodUser } from "../../support/constants";

describe("View create/edit action tests", () => {
  const table_shortname = "table1";

  const viewDef: ViewDefinition = {
    name: "Test view",
    filters: [
      {
        field: "Text Field",
        operator: "equal",
        value: "RECORD 5 \\<",
        typeahead: false
      },
      {
        field: "Dropdown Field",
        operator: "equal",
        value: "Blue",
        typeahead: true
      },
      {
        field: "Dropdown Field",
        operator: "equal",
        value: "Red",
        typeahead: true
      },
      {
        field: "Number Field",
        operator: "equal",
        value: "123456789087654321",
        typeahead: false
      }
    ],
    fields: ["Text Field", "Date Field", "Dropdown Field", "Number Field"]
  };

    const ErrViewDef: ViewDefinition = {
    name: "Erroring view: This view name has over one hundred and twenty nine charecters so therefore should error upon save. Should this view name successfully save then the test will fail and I shall be very sad :(",
    filters: [
      {
        field: "Date Field",
        operator: "equal",
        value: "111:111:111",
        typeahead: false
      },
      {
        field: "Number Field",
        operator: "equal",
        value: "123 aabc",
        typeahead: false
      },
      {
        field: "Dropdown Field",
        operator: "equal",
        value: "Red",
        typeahead: true
      }

    ],
    fields: ["Text Field", "Date Field", "Dropdown Field", "Serial"]
  };

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
    cy.populateTableWithLayouts("my_table_shortname");
    cy.clearImports(table_shortname);
    cy.bulkImportRecords();
    cy.clearImports(table_shortname);
    cy.logout();
  });

  beforeEach(() => {
    cy.login(goodUser, goodPassword);
    cy.gotoInstanceByShortName("table1", "data");
  });

  afterEach(() => {
    cy.log("Deleting view");
    cy.gotoInstanceByShortName("table1", "data")
      .get("span").contains("Manage views").click()
      .get('a[role="menuitem"]').contains("Edit current view").click()
      .get(".btn-js-delete").contains("Delete view").click()
      .get('button[type="submit"]').contains("Delete").click();
  });

  after(() => {
    cy.deleteAllData("table1");
    cy.purgeAllDeletedData("table1");
    cy.cleanTableOfLayouts("table1");
    cy.clearAllTablePermissions("table1");
    cy.addUserToDefaultGroup("test@example.com", "uncheck");
  });

    it("Creates a personal view with all fields then edits with no fileds", () => {
        cy.log("Creating a view")
        .get("span").contains("Manage views").click()
        .get('a[role="menuitem"]').contains("Add a view").click()
        .get('input[name="name"]').type(viewDef.name)
        .get("span").contains("Fields").click()

        .get('#table-view-fields-selected tbody tr').each(($row) => {
            cy.wrap($row).should('have.attr', 'data-field-is-toggled', 'false')
            cy.wrap($row).find('input[type="checkbox"]').should('not.be.checked');
        });

        cy.get('button.btn-js-toggle-all-fields').contains('Select all fields').click();


        cy.get('#table-view-fields-selected tbody tr').each(($row) => {
            cy.wrap($row).should('have.attr', 'data-field-is-toggled', 'true');
            cy.wrap($row).find('input[type="checkbox"]').should('be.checked');
        });

        cy.get('button[type="submit"]').contains("Save").click();
        cy.contains("span", "Current view: Test view").should("exist");
        cy.get('thead th').contains('Text Field').should('exist');
        cy.get('thead th').contains('Number Field').should('exist');
        cy.get('thead th').contains('Date Field').should('exist');
        cy.get('thead th').contains('Range Field').should('exist');
        cy.get('thead th').contains('Dropdown Field').should('exist');



        cy.get("span").contains("Manage views").click()
       .get('a[role="menuitem"]').contains("Edit current view").click()
       .get("span").contains("Fields").click()
       .get('#table-view-fields-selected tbody tr').each(($row) => {
            cy.wrap($row).should('have.attr', 'data-field-is-toggled', 'true');
            cy.wrap($row).find('input[type="checkbox"]').should('be.checked');
       });

       cy.get('button.btn-js-toggle-all-fields').contains('Remove all fields').click();

       cy.get('#table-view-fields-selected tbody tr').each(($row) => {
            cy.wrap($row).should('have.attr', 'data-field-is-toggled', 'false')
            cy.wrap($row).find('input[type="checkbox"]').should('not.be.checked');
        });

        cy.get('button[type="submit"]').contains("Save").click();
        cy.get('thead th').contains('ID').should('exist');
        cy.get('thead th').contains('Text Field').should('not.exist');
        cy.get('thead th').contains('Number Field').should('not.exist');
        cy.get('thead th').contains('Date Field').should('not.exist');
        cy.get('thead th').contains('Range Field').should('not.exist');
        cy.get('thead th').contains('Dropdown Field').should('not.exist');
      });

  it("Creates a personal view with dropdown filter from a typeahead", () => {
    cy.log("Creating a view")
      .get("span").contains("Manage views").click()
      .get('a[role="menuitem"]').contains("Add a view").click()
      .get('input[name="name"]').type(viewDef.name)
      .get("span").contains("Filter").click()
      .get("button").contains("Add rule").click()
      .get("div.filter-option-inner-inner").click()
      .get('a[role="option"]').contains(viewDef.filters[1].field).click()
      .get("div.filter-option-inner-inner").contains("equal").click()
      .get('a[role="option"]').contains(viewDef.filters[1].operator).click()
      .get("input.tt-input").type(
        viewDef.filters[1].typeahead
          ? viewDef.filters[1].value.slice(0, 2)
          : viewDef.filters[1].value
      )
      .get("div.tt-suggestion").contains(viewDef.filters[1].value).click()
      .get("span").contains("Fields").click();

    for (const field of viewDef.fields) {
      cy.get("#table-view-fields-available").find("td.check").contains(field).click();
    }

    cy.get('button[type="submit"]').contains("Save").click();
    cy.contains("span", "Current view: Test view").should("exist");
    cy.get("td.dt-empty").should("not.exist");
  });

  it("Creates a personal with text filter, followed by an edit", () => {
    cy.log("Creating a view")
      .get("span").contains("Manage views").click()
      .get('a[role="menuitem"]').contains("Add a view").click()
      .get('input[name="name"]').type(viewDef.name)
      .get("span").contains("Filter").click()
       .get("button").contains("Add rule").click()
       .get("div.filter-option-inner-inner").contains("------").click()
       .get(".dropdown-menu.show").last()
       .find('a[role="option"]').not('[aria-hidden="true"]').contains(viewDef.filters[0].field).click()
       .get('input.form-control[type="text"]').last()
       .type(viewDef.filters[0].value);                  


    cy.get('button[type="submit"]').contains("Save").click();
    cy.contains("span", "Current view: Test view").should("exist");
    cy.get("td.dt-empty").should("not.exist");
    cy.contains("Showing 1 to 1 of 1 entry").should("be.visible");

    cy.log("Editing the view to add a filter")
      .get("span").contains("Manage views").click()
      .get('a[role="menuitem"]').contains("Edit current view").click()
      .get("span").contains("Filter").click()
       .get("button").contains("Add rule").click()
       .get("div.filter-option-inner-inner").contains("------").click()
       .get(".dropdown-menu.show").last()
       .find('a[role="option"]').not('[aria-hidden="true"]').contains(viewDef.filters[1].field).click()
       .get('input.tt-input:visible').last()
       .type(
           viewDef.filters[1].typeahead
           ? viewDef.filters[1].value.slice(0, 2)
           : viewDef.filters[1].value
       )
       .get("div.tt-suggestion").contains(viewDef.filters[1].value).click()
       cy.get('button[type="submit"]').contains("Save").click(); 
       cy.contains("span", "Current view: Test view").should("exist"); 
       cy.get("td.dt-empty").should("not.exist"); 
       cy.contains("Showing 1 to 1 of 1 entry").should("be.visible");
       
       cy.log("Editing the view again to add a 3rd filter and fields")
       .get("span").contains("Manage views").click()
       .get('a[role="menuitem"]').contains("Edit current view").click()
       .get("span").contains("Filter").click()
       .get("button").contains("Add rule").click()
       .get("div.filter-option-inner-inner").contains("------").click()
       .get(".dropdown-menu.show").last()
       .find('a[role="option"]').not('[aria-hidden="true"]').contains(viewDef.filters[2].field).click()
       .get('input.tt-input:visible').last()
       .type(
           viewDef.filters[2].typeahead
           ? viewDef.filters[2].value.slice(0, 1)
           : viewDef.filters[2].value
       )
       .get("div.tt-suggestion").contains(viewDef.filters[2].value).click()
       .get("span").contains("Fields").click();
       
       for (const field of viewDef.fields) {
           cy.get("#table-view-fields-available").find("td.check").contains(field).click();
       }

       cy.get('button[type="submit"]').contains("Save").click(); 
       cy.contains("span", "Current view: Test view").should("exist"); 
       cy.get("td.dt-empty").should("exist"); 
       cy.contains("Showing 0 to 0 of 0 entries").should("be.visible");
       cy.get('thead th').contains('Date Field').should('exist');
       cy.get('thead th').contains('Text Field').should('exist');
       cy.get('thead th').contains('Dropdown Field');
  });

      it("Creates a personal view with a ASC sort", () => {
        cy.log("Creating a view with ASC serial sort")
        .get("span").contains("Manage views").click()
        .get('a[role="menuitem"]').contains("Add a view").click()
        .get('input[name="name"]').type(viewDef.name)
        .get("span").contains("Sort/Group").click()
        .get('#btn-sortfield').click()
        .get(".dropdown-menu.show").last()
        .find('li[role="option"]').contains("Serial").click()
        
        .get("span").contains("Fields").click();
        for (const field of ErrViewDef.fields) {
            cy.get("#table-view-fields-available").find("td.check").contains(field).click();
       }
       cy.get('button[type="submit"]').contains("Save").click();
       cy.contains("span", "Current view: Test view").should("exist");
       cy.get("td.dt-empty").should("not.exist")
       cy.get('thead th').contains('Serial').should('exist');
       
       cy.get('td.sorting_1').then($cells => {
           const firstFive = [...$cells].slice(0, 5).map(cell => parseInt(cell.innerText.trim(), 10));
           expect(firstFive).to.deep.equal([1, 2, 3, 4, 5]);
       });
       
       cy.log("Edit view to DESC serial sort")
       cy.gotoInstanceByShortName("table1", "data")
       .get("span").contains("Manage views").click()
       .get('a[role="menuitem"]').contains("Edit current view").click()
       .get("span").contains("Sort/Group").click()
       .get('#btn-sorttype').click()
       .get('li.select__menu-item[role="option"][data-value="desc"]').contains('Descending').click();
    
       cy.get('button[type="submit"]').contains("Save").click();
       cy.contains("span", "Current view: Test view").should("exist");
       cy.get("td.dt-empty").should("not.exist")
       cy.get('thead th').contains('Serial').should('exist');

       cy.get('td.sorting_1').then($cells => {
           const firstFive = [...$cells].slice(0, 5).map(cell => parseInt(cell.innerText.trim(), 10));
           const sortedDesc = [...firstFive].sort((a, b) => b - a);
           expect(firstFive).to.deep.equal(sortedDesc);
       });
      });

it("Attempts to create views with errors", () => {
    
    cy.log("Creating a view with blank name")
      .get("span").contains("Manage views").click()
      .get('a[role="menuitem"]').contains("Add a view").click()
      .get('button[type="submit"]').contains("Save").click()
      .get('div.alert.alert-danger[role="alert"]').should('contain', 'ERROR:').and('contain', 'Please enter a name')
      
      .get('input[name="name"]').type(ErrViewDef.name)
      .get('button[type="submit"]').contains("Save").click()
      .get('div.alert.alert-danger[role="alert"]').should('contain', 'ERROR:').and('contain', 'View name must be less than 128 characters')


  // checks for invalid date type error.
  cy.log("Attempt to save the view with incorrect date value")
    .get('input[name="name"]').clear()
    .get('input[name="name"]').type(viewDef.name)
    .get("span").contains("Filter").click()
    .get("button").contains("Add rule").click()
    .get("div.filter-option-inner-inner").contains("------").click()
    .get(".dropdown-menu.show").last()
    .find('a[role="option"]').not('[aria-hidden="true"]')
    .contains(ErrViewDef.filters[0].field).click()
    .get('input.form-control[type="text"]').last().type(ErrViewDef.filters[0].value)
    .get('button[type="submit"]').contains("Save").click()
    .get('div.alert.alert-danger[role="alert"]')
    .should('contain', 'ERROR:')
    .and('contain', 'Invalid date');

  // checks for invalid int type error.
  cy.log("Attempt to save the view with incorrect int value")
    .get("span").contains("Filter").click()
    .get("div.filter-option-inner-inner").contains(ErrViewDef.filters[0].field).click()
    .get(".dropdown-menu.show")
    .find('a[role="option"]').not('[aria-hidden="true"]')
    .contains(ErrViewDef.filters[1].field).click()
    .get('input.form-control[type="text"]').last().type(ErrViewDef.filters[1].value)
    .get('button[type="submit"]').contains("Save").click()
    .get('div.alert.alert-danger[role="alert"]').should('contain', 'ERROR:').and('contain', 'not a valid integer');

  // Finally create a working view to end the erroring test.
  cy.log("Attempt to resave the view with correct data types")
    .get("span").contains("Filter").click()
    .get("div.filter-option-inner-inner").contains(ErrViewDef.filters[1].field).click()
    .get(".dropdown-menu.show")
    .find('a[role="option"]').not('[aria-hidden="true"]')
    .contains(viewDef.filters[3].field).click()
    .get('input.form-control[type="text"]').last().clear().type(viewDef.filters[3].value)
    .get('button[type="submit"]').contains("Save").click();

  cy.contains("span", "Current view: Test view").should("exist");
  cy.get("td.dt-empty").should("exist");
  cy.contains("Showing 0 to 0 of 0 entries").should("be.visible");
  });
  
});
