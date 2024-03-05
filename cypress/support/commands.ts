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
declare global {
    namespace Cypress {
        interface Chainable {
            getByName(name: string): Chainable<JQuery<HTMLElement>>;
            getByTitle(title: string): Chainable<JQuery<HTMLElement>>;
            loginAndGoTo(email:string, password:string, path:string): Chainable<JQuery<Element>>;
            mainBody(): Chainable<JQuery<HTMLElement>>;
            mainHeader(): Chainable<JQuery<HTMLElement>>;
            getDataTable(): Chainable<JQuery<HTMLElement>>;
        }
    }
}

Cypress.Commands.add('getByName', (name: string) => {
    return cy.get(`[name=${name}]`);
});

Cypress.Commands.add('getByTitle', (title: string) => {
    return cy.get(`[title=${title}]`);
});

Cypress.Commands.add('loginAndGoTo', (email:string, password:string, path:string) => {
    cy.visit('http://localhost:3000');
    cy.get("#username").type(email);
    cy.get("#password").type(password);
    cy.getByName("signin").click();
    cy.location("pathname").should("not.include", "/login");
    cy.visit(path);
});

Cypress.Commands.add('mainBody',()=>{
    return cy.get(".content-block__main");
});

Cypress.Commands.add('mainHeader',()=>{
    return cy.get(".content-block__head");
});

Cypress.Commands.add('getDataTable',()=>{
    return cy.mainBody().find(".data-table");
});
