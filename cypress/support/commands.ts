/* eslint-disable @typescript-eslint/no-namespace */
/// <reference types="cypress" />

import 'cypress-axe';
import { LayoutDefinition } from "./builders/layout/definitions";
import { IBuildable, IDropdownLayoutBuilder } from "./builders/layout/interfaces";
import { LayoutBuilder } from "./builders/layout/LayoutBuilder";
import { instanceMode, tablePermissions } from "./constants";
import { goodPassword, goodUser } from "./constants";

export { }

declare global {
    namespace Cypress {
        interface Chainable {
            getByName(name: string): Chainable;
            getByTitle(title: string): Chainable;
            login(email: string, password: string): Chainable;
            loginAndGoTo(email: string, password: string, path: string): Chainable;
            mainBody(): Chainable;
            mainHeader(): Chainable;
            getDataTable(): Chainable;
            createTitle(title: string): Chainable;
            createOrganisation(title: string): Chainable;
            createGroup(title: string): Chainable;
            addUserGroup(email: string, group: string): Chainable;
            deleteGroup(title: string): Chainable;
            createLayout(builder: IBuildable, navigate?: boolean): Chainable;
            deleteLayoutByShortName(shortName: string, navigate?: boolean): Chainable;
            createInstance(instanceName: string, shortName?: string): Chainable;
            gotoInstanceByShortName(shortName: string, mode: instanceMode): Chainable;
            deleteInstanceByShortName(shortName: string): Chainable;
            setFieldValueByShortName(shortName: string, value: string | { to: string, from: string }): Chainable;
            setTablePermissionsByShortName(shortName: string, permissions: { [key in tablePermissions]?: boolean }): Chainable;
            createLayoutsFromDefinition(layoutDefs: LayoutDefinition): Chainable;
            addUserToDefaultGroup(user: string, CheckOrUncheck?: 'check' | 'uncheck'): Chainable;
            addDataToLayoutFromDefinition(layoutDefs: LayoutDefinition): Chainable;
            deleteAllData(table: string): Chainable;
            purgeAllDeletedData(shortName: string): Chainable;
            deleteLayoutsFromDefinitions(layoutDefs: LayoutDefinition): Chainable;
            clearAllTablePermissions(shortName: string): Chainable;
            populateTableWithLayouts(shortName: string): Chainable;
            cleanTableOfLayouts(shortName: string): Chainable;
            clearImports(shortName: string): Chainable;
            bulkImportRecords(csvFilePath?: string): Chainable;
            logout(): Chainable;
            deleteCurrentView(): Chainable;
            deleteAllViewsForTable(tableName: string): Chainable;
        }
    }
}

Cypress.Commands.add('getByName', (name: string) => {
    return cy.get(`[name=${name}]`);
});

Cypress.Commands.add('getByTitle', (title: string) => {
    return cy.get(`[title=${title}]`);
});

Cypress.Commands.add("login", (email: string, password: string) => {
    return cy.visit('http://localhost:3000')
        .get("#username").type(email)
        .get("#password").type(password)
        .getByName("signin").click()
        .location("pathname").should("not.include", "/login");
});

Cypress.Commands.add('loginAndGoTo', (email: string, password: string, path: string) => {
    return cy.login(email, password).visit(path);
});

Cypress.Commands.add('mainBody', () => {
    return cy.get(".content-block__main");
});

Cypress.Commands.add('mainHeader', () => {
    return cy.get(".content-block__head");
});

Cypress.Commands.add('getDataTable', () => {
    return cy.mainBody().find(".data-table");
});

Cypress.Commands.add('createTitle', (title: string) => {
    if (!location.pathname.match(/title_add/)) {
        cy.visit('http://localhost:3000/settings/title_add/');
    }
    return cy.mainBody().find("input[name='title']").type(title)
        .mainBody().find("button[type='submit']").click()
        .getDataTable().find("tbody tr").contains(title);
});

Cypress.Commands.add('createOrganisation', (title: string) => {
    if (!location.pathname.match(/organisation_add/)) {
        cy.visit('http://localhost:3000/settings/organisation_add/');
    }
    return cy.mainBody().find("input[name='title']").type(title)
        .mainBody().find("button[type='submit']").click()
        .getDataTable().find("tbody tr").contains(title);
});

Cypress.Commands.add('createGroup', (title: string) => {
    if (!location.pathname.match(/group_add/)) {
        cy.visit('http://localhost:3000/group_add/');
    }
    return cy.mainBody().find('input[name="name"]').type(title)
        .mainBody().find("button[type='submit']").click()
        .getDataTable().find("tbody tr").contains(title);
});

Cypress.Commands.add('addUserGroup', (email: string, group: string) => {
    if (!location.pathname.match('/user_overview/')) {
        cy.visit('http://localhost:3000/user_overview/');
    }
    return cy.get('tr').contains('td', email).parent().click()
        .get('label.checkbox-label').contains(group).prev('input[type="checkbox"]').check({ force: true })
        .mainBody().find("button[type='submit']").click();
});

Cypress.Commands.add('deleteGroup', (title: string) => {
    if (!location.pathname.match(/group_overview/)) {
        cy.visit('http://localhost:3000/group_overview/');
    }
    return cy.contains('a', title).click()
        .get('.btn-delete').click()
        .get('.btn.btn-danger').click();
});

Cypress.Commands.add('createLayout', (builder: IBuildable, navigate = false) => {
    builder.build(navigate);
    return cy.mainBody();
});

Cypress.Commands.add('deleteLayoutByShortName', (shortName: string, navigate = false) => {
    if (navigate) {
        cy.visit("http://localhost:3000/table")
            .getDataTable().find("a").contains("Edit table").click();
        cy.get("a").contains("Fields").click();
    }
    return cy.getDataTable().find("tbody tr td").contains(shortName).click()
        .get(".btn-danger").contains("Delete field").click()
        .get(".modal .btn-danger").contains("Delete").click();
});

Cypress.Commands.add("createInstance", (instanceName: string, shortname: string = instanceName.toLowerCase().replace(" ", "")) => {
    return cy.visit("http://localhost:3000/table")
        .get("button").contains("New table").click()
        .get(".modal").should("be.visible")
        .find("input#name[name=name]").type(instanceName)
        .get("input[name=shortName]").type(shortname)
        .get("button.btn-js-next").contains("Next").click()
        .get("button.btn-js-save").contains("Save table").click();
});

Cypress.Commands.add("gotoInstanceByShortName", (shortName: string, mode: instanceMode) => {
    return cy.visit(`http://localhost:3000/${shortName}/${mode ? mode : ""}`);
});

Cypress.Commands.add("deleteInstanceByShortName", (shortName: string) => {
    return cy.gotoInstanceByShortName(shortName, "edit")
        .get("button").contains("Delete table").click()
        .get(".modal").should("be.visible")
        .find("button").contains("Delete").click();
});

Cypress.Commands.add("setFieldValueByShortName", (shortName: string, value: string | { to: string, from: string }) => {
    return cy.get(`[data-name-short="${shortName}"]`).then(($el) => {
        const type = $el.data('column-type');
        if (["string", "intgr", "date", "daterange"].includes(type)) {
            const input = $el.find("input");
            cy.wrap(input).then(($input) => {
                if (type === "daterange") {
                    if (typeof value !== "object") throw new Error("Value must be an object with 'to' and 'from'");
                    cy.wrap($input).eq(0).type(value.from);
                    cy.wrap($input).eq(1).type(value.to);
                } else {
                    if (typeof value !== "string") throw new Error("Value must be a string");
                    cy.wrap($input).type(value);
                }
            });
        } else if (type === "enum") {
            cy.wrap($el.find(".form-control")).click();
            cy.get(`[data-value="${value}"]`).click({ force: true });
        }
    });
});

Cypress.Commands.add("setTablePermissionsByShortName", (shortName: string, permissions: { [key in tablePermissions]?: boolean }) => {
    cy.gotoInstanceByShortName(shortName, "edit")
        .get("a").contains("Permissions").click()
        .get("span").contains('basic').click();
    for (const [group, permission] of Object.entries(permissions)) {
        cy.get("label").contains(group).then(($label) => {
            const target = $label.attr("for");
            cy.get(`input#${target}`)[permission ? "check" : "uncheck"]({ force: true });
        });
    }
    return cy.get("button").contains("Save").click();
});

Cypress.Commands.add("createLayoutsFromDefinition", (layoutDefs: LayoutDefinition) => {
    for (const [layoutType, layoutDef] of Object.entries(layoutDefs)) {
        const builder = LayoutBuilder.create(<any>layoutType).withName(layoutDef.name).withShortName(layoutDef.shortName);
        if ("options" in layoutDef && layoutDef.options) {
            for (const option of layoutDef.options.values) {
                (builder as IDropdownLayoutBuilder).addOption(option);
            }
        }
        cy.createLayout(builder, true);
        builder.checkField();
    }
    return cy.mainBody();
});

Cypress.Commands.add("addUserToDefaultGroup", (user: string, CheckOrUncheck: 'check' | 'uncheck' = 'check') => {
    return cy.visit('http://localhost:3000/user_overview/')
        .get('td').contains(user).click()
        .get('input#groups_1')[CheckOrUncheck]({ force: true })
        .get('button[name="submit"]').click();
});

Cypress.Commands.add("addDataToLayoutFromDefinition", (layoutDefs: LayoutDefinition) => {
    cy.visit('http://localhost:3000/table1/data');
    cy.get('a.btn-add').contains('Add a record').click();
    for (const layoutDef of Object.values(layoutDefs)) {
        cy.setFieldValueByShortName(layoutDef.shortName, layoutDef.data!);
    }
    return cy.get('button[name="submit"]').contains("Submit and exit").click();
});

Cypress.Commands.add("deleteAllData", (table: string) => {
    return cy.setTablePermissionsByShortName(table, { "Delete records": true, "Purge deleted records": true, "Bulk delete records": true })
        .gotoInstanceByShortName(table, "data")
        .get("button").contains("Actions").click()
        .get("a[data-target='#bulkDelete']").click()
        .get("button[type='submit']").contains("Delete").click();
});

Cypress.Commands.add("purgeAllDeletedData", (shortName: string) => {
    return cy.visit(`http://localhost:3000/${shortName}/purge`)
        .get("input[type='checkbox']").check({ force: true })
        .get("button[data-target='#purge']").click()
        .get("button[type='submit']").contains("Confirm").click();
});

Cypress.Commands.add("deleteLayoutsFromDefinitions", (layoutDefs: LayoutDefinition) => {
    for (const layoutDef of Object.values(layoutDefs)) {
        cy.deleteLayoutByShortName(layoutDef.shortName, true);
    }
    return cy.mainBody();
});

Cypress.Commands.add("clearAllTablePermissions", (shortName: string) => {
    const permissions: { [key in tablePermissions]?: boolean } = {
        "Delete records": false, "Purge deleted records": false, "Download records": false,
        "Bulk import records": false, "Bulk update records": false, "Bulk delete records": false,
        "Manage linked records": false, "Manage child records": false, "Manage views": false,
        "Manage group views": false, "Select extra view limits": false, "Manage fields": false,
        "Send messages": false
    };
    cy.setTablePermissionsByShortName(shortName, permissions);
    return cy.mainBody();
});

Cypress.Commands.add("populateTableWithLayouts", () => {
    const layoutDefs: LayoutDefinition = {
        "TEXT": { name: "Text Field", shortName: "txt_fd" },
        "INTEGER": { name: "Number Field", shortName: "int_fd" },
        "DROPDOWN": { name: "Dropdown Field", shortName: "drop_fd", options: { values: ["Red", "Green", "Blue"]}},
        "DATE": { name: "Date Field", shortName: "date_fd" },
        "DATE-RANGE": { name: "Range Field", shortName: "range_fd" },
    };
    return cy.createLayoutsFromDefinition(layoutDefs);
});

Cypress.Commands.add("cleanTableOfLayouts", () => {
    const layoutDefs: LayoutDefinition = {
        "TEXT": { name: "Text Field", shortName: "txt_fd" },
        "INTEGER": { name: "Number Field", shortName: "int_fd" },
        "DATE": { name: "Date Field", shortName: "date_fd" },
        "DATE-RANGE": { name: "Range Field", shortName: "range_fd" },
        "DROPDOWN": { name: "Dropdown Field", shortName: "drop_fd", options: { values: ["Red", "Green", "Blue"]}}
    };
    return cy.deleteLayoutsFromDefinitions(layoutDefs);
});

Cypress.Commands.add("clearImports", (shortName) => {
    cy.visit(`http://localhost:3000/${shortName}/import`);
    cy.contains('button.btn-danger', 'Clear completed reports').click();
    cy.get('#deleteModal').should('be.visible').within(() => {
        cy.contains('button', 'Confirm').click();
    });
    return cy.get('td.dt-empty').should('contain.text', 'No imports to show');
});

Cypress.Commands.add("bulkImportRecords", (csvFilePath = 'cypress/fixtures/Import-test-data.csv') => {
    cy.visit('http://localhost:3000/table1/data');
    cy.get('button#bulk_actions').click();
    cy.get('a[href="/table1/import/"]').click();
    cy.get('h2.table-header__page-title').should('contain.text', 'Import records');
    cy.get('a[href="/table1/import/data/"]').click();
    cy.get('h2.table-header__page-title').should('contain.text', 'Upload');
    cy.get("label").contains("Dry run").then(($label) => {
        const target = $label.attr("for");
        cy.get(`input#${target}`).uncheck({ force: true });
    });
    cy.get('input[type="file"]').selectFile(csvFilePath, { force: true });
    cy.contains('Submit').click();
    cy.get('.alert.alert-success').should('be.visible').and('contain.text', 'The file import process has been started');
    cy.wait(5000);
    cy.visit('http://localhost:3000/table1/import');
    cy.get('a.link--plain').contains('Completed').should('exist');
    cy.get('a.link--plain').contains(/errors:\s*0/);
    cy.get('a.link--plain').contains(/skipped:\s*0/);
    return cy.mainBody();
});

Cypress.Commands.add('logout', () => {
    return cy.get('a[href="/logout"]').click();
});

Cypress.Commands.add('deleteCurrentView', () => {
    cy.contains("Manage views").click();
    cy.get('a[role="menuitem"]').contains("Edit current view").click();
    cy.get(".btn-js-delete").contains("Delete view").click();
    return cy.get('button[type="submit"]').contains("Delete").click();
});

Cypress.Commands.add('deleteAllViewsForTable', (tableName: string) => {
    cy.logout();
    cy.login(goodUser, goodPassword);
    cy.visit(`http://localhost:3000/${tableName}/data`);
    const checkAndDelete = () => {
        cy.get('.dropdown__toggle span').invoke('text').then((text) => {
            if (!text.includes('All data')) {
                cy.deleteCurrentView();
                checkAndDelete();
            }
        });
    };
    checkAndDelete();
    return cy.mainBody();
});
