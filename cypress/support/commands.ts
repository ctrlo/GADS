/// <reference types="cypress" />

import { IBuildable } from "./builders/layout/interfaces";
import { instanceMode } from "./constants";

export { }

declare global {
    namespace Cypress {
        interface Chainable {
            /**
             * Get a component by name
             * @param name The name of the element to get
             * @example cy.getByName('username')
             */
            getByName(name: string): Chainable<JQuery<HTMLElement>>;
            /**
             * Get a component by title
             * @param title The title of the element to get
             * @example cy.getByTitle('username')
             */
            getByTitle(title: string): Chainable<JQuery<HTMLElement>>;
            /**
             * Login to the application
             * @param email The email to use to login
             * @param password The password to use to login
             * @example cy.login('username@example.com','password')
             */
            login(email: string, password: string): void;
            /**
             * Login then navigate to a page
             * @param email The email to use to login
             * @param password The password to use to login
             * @param path The location to navigate to after login
             * @example cy.loginAndGoTo('username@example.com','password','/home')
             */
            loginAndGoTo(email: string, password: string, path: string): void;
            /**
             * Get the main body of the page
             * @example cy.mainBody() - this is the same as `cy.get('.content-block__main')`
             * @see login
             */
            mainBody(): Chainable<JQuery<HTMLElement>>;
            /**
             * Get the main header of the page
             * @example cy.mainHeader() - this is the same as `cy.get('.content-block__head')`
             */
            mainHeader(): Chainable<JQuery<HTMLElement>>;
            /**
             * Get the data table of the page
             * @example cy.getDataTable() - this is the same as `cy.mainBody().find('.data-table')`
             */
            getDataTable(): Chainable<JQuery<HTMLElement>>;
            /**
             * Create a title in the system
             * @param title The title to create in the system
             * @example cy.createTitle('New Title')
             */
            createTitle(title: string): void;
            /**
             * Create an organisation in the system
             * @param title The title of the organisation to create
             * @example cy.createOrganisation('New Organisation')
             */
            createOrganisation(title: string): void;
            /**
             * Create a group in the system
             * @param title The title of the group to create
             * @example cy.createGroup('New Group')
             */
            createGroup(title: string): void;
            /**
             * Add a user to a group
             * @param email The email of the user to add to the group
             * @param group The name of the group to add the user to
             * @example cy.addUserGroup('bob@home.com','Admin')
             * @see createGroup 
             */
            addUserGroup(email: string, group: string): void;
            /**
             * Delete a group from the system
             * @param title The title of the group to delete
             * @example cy.deleteGroup('Admin')
             */
            deleteGroup(title: string): void;
            /**
             * Create a layout in the system
             * @param builder The layout builder to use to create the layout
             * @example cy.createLayout(LayoutBuilder.createBuilder('TEXT').setName('test').setShortName('t'))
             */
            createLayout(builder: IBuildable): void;
            /**
             * Create a layout in the system
             * @param builder The layout builder to use to create the layout
             * @param navigate Whether to navigate to the layout page before creating the layout
             * @example cy.createLayout(LayoutBuilder.createBuilder('TEXT').setName('test').setShortName('t'), true)
             */
            createLayout(builder: IBuildable, navigate: boolean): void;
            /**
             * Delete a layout by short name
             * @param shortName The short name of the layout to delete
             * @example cy.deleteLayoutByShortName('t')
             */
            deleteLayoutByShortName(shortName: string): void;
            /**
             * Delete a layout by short name
             * @param shortName The short name of the layout to delete
             * @param navigate Whether to navigate to the layout page before deleting the layout
             * @example cy.deleteLayoutByShortName('t')
             */
            deleteLayoutByShortName(shortName: string, navigate: boolean): void;
            /**
             * Create an instance in the system
             * @param instanceName The name of the instance to create
             * @example cy.createInstance('Test Instance')
             */
            createInstance(instanceName: string, shortName?: string): void;
            /**
             * Go to an instance by short name
             * @param shortName The short name of the instance to go to
             * @example cy.gotoInstanceByShortName('test')
             */
            gotoInstanceByShortName(shortName: string, mode: instanceMode): void;
            /**
             * Delete a instance by short name
             * @param shortName The short name of the instance to delete
             * @example cy.deleteInstanceByShortName('t')
             */
            deleteInstanceByShortName(shortName: string): void;
        }
    }
}

Cypress.Commands.add('getByName', (name: string) => cy.get(`[name=${name}]`));

Cypress.Commands.add('getByTitle', (title: string) => cy.get(`[title=${title}]`));

Cypress.Commands.add("login", (email: string, password: string) => {
    cy.visit('http://localhost:3000');
    cy.get("#username").type(email);
    cy.get("#password").type(password);
    cy.getByName("signin").click();
    cy.location("pathname").should("not.include", "/login");
});

Cypress.Commands.add('loginAndGoTo', (email: string, password: string, path: string) => {
    cy.login(email, password);
    cy.visit(path);
});

Cypress.Commands.add('mainBody', () => cy.get(".content-block__main"));

Cypress.Commands.add('mainHeader', () => cy.get(".content-block__head"));

Cypress.Commands.add('getDataTable', () => cy.mainBody().find(".data-table"));

Cypress.Commands.add('createTitle', (title: string) => {
    if (!location.pathname.match(/title_add/)) {
        cy.visit('http://localhost:3000/settings/title_add/');
    }
    cy.mainBody().find("input[name='title']").type(title);
    cy.mainBody().find("button[type='submit']").click();
    cy.getDataTable().find("tbody").find("tr").contains(title);
});

Cypress.Commands.add('createOrganisation', (title: string) => {
    if (!location.pathname.match(/organisation_add/)) {
        cy.visit('http://localhost:3000/settings/organisation_add/');
    }
    cy.mainBody().find("input[name='title']").type(title);
    cy.mainBody().find("button[type='submit']").click();
    cy.getDataTable().find("tbody").find("tr").contains(title);
});

Cypress.Commands.add('createGroup', (title: string) => {
    if (!location.pathname.match(/group_add/)) {
        cy.visit('http://localhost:3000/group_add/');
    }
    cy.mainBody().find('input[name="name"]').type(title);
    cy.mainBody().find("button[type='submit']").click();
    cy.getDataTable().find("tbody").find("tr").contains(title);
});

Cypress.Commands.add('addUserGroup', (email: string, group: string) => {
    if (!location.pathname.match('/user_overview/')) {
        cy.visit('http://localhost:3000/user_overview/');
    }
    cy.get('tr').contains('td', email).parent().click();
    cy.get('label.checkbox-label').contains(group).prev('input[type="checkbox"]').check({ force: true });
    cy.mainBody().find("button[type='submit']").click();
});


Cypress.Commands.add('deleteGroup', (title: string) => {
    if (!location.pathname.match(/group_overview/)) {
        cy.visit('http://localhost:3000/group_overview/');
    }
    cy.contains('a', title).click();
    cy.get('.btn-delete').click();
    cy.get('.btn.btn-danger').click();
});

Cypress.Commands.add('createLayout', (builder: IBuildable, navigate: boolean = false) => {
    builder.build(navigate);
});

Cypress.Commands.add('deleteLayoutByShortName', (shortName: string, navigate: boolean = false) => {
    if (navigate) {
        cy.visit("http://localhost:3000/table");
        cy.getDataTable()
            .find("a")
            .contains("Edit table")
            .click();
        cy.get("a")
            .contains("Fields")
            .click();
    }
    cy.getDataTable()
        .find("tbody")
        .find("tr")
        .find("td")
        .contains(shortName)
        .click();
    cy.get(".btn-danger")
        .contains("Delete field")
        .click();
    cy.get(".modal")
        .find(".btn-danger")
        .contains("Delete")
        .click();
});

Cypress.Commands.add("createInstance", (instanceName: string, shortname: string = instanceName.toLocaleLowerCase().replace(" ", "")) => {
    cy.visit("http://localhost:3000/table");
    cy.get("button")
        .contains("New table")
        .click();
    cy.get(".modal")
        .should("be.visible")
        .find("input#name[name=name]")
        .type(instanceName);
    cy.get("input[name=shortName]")
        .type(shortname);
    cy.get("button.btn-js-next")
        .contains("Next")
        .should("be.visible")
        .click();
    cy.get("button.btn-js-save")
        .contains("Save table")
        .should("be.visible")
        .click();
});

Cypress.Commands.add("gotoInstanceByShortName", (shortName: string, mode: instanceMode) => {
    cy.visit(`http://localhost:3000/${shortName}/${mode ? mode : ""}`);
});

Cypress.Commands.add("deleteInstanceByShortName", (shortName: string) => {
    cy.gotoInstanceByShortName(shortName, "edit");
    cy.get("button")
        .contains("Delete table")
        .click();
    cy.get(".modal")
        .should("be.visible")
        .find("button")
        .contains("Delete")
        .click();
});
