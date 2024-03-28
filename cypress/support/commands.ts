/// <reference types="cypress" />
// ***********************************************
// This example commands.ts shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add('login', (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add('drag', { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add('dismiss', { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })
//
// declare global {
//   namespace Cypress {
//     interface Chainable {
//       login(email: string, password: string): Chainable<void>
//       drag(subject: string, options?: Partial<TypeOptions>): Chainable<Element>
//       dismiss(subject: string, options?: Partial<TypeOptions>): Chainable<Element>
//       visit(originalFn: CommandOriginalFn, url: string, options: Partial<VisitOptions>): Chainable<Element>
//     }
//   }
// }
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
        }
    }
}

export const goodUser = "test@example.com";
export const goodPassword = "xyz123";

Cypress.Commands.add('getByName', (name: string) => {
    return cy.get(`[name=${name}]`);
});

Cypress.Commands.add('getByTitle', (title: string) => {
    return cy.get(`[title=${title}]`);
});

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
