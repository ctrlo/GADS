/// <reference types="cypress" />
describe('Login Tests', () => {
  const errorText = "The username or password was not recognised";
  const goodUser = "test@example.com"
  const goodPassword = "xyz123";

  beforeEach(()=>{
    cy.visit('http://localhost:3000');
  })

  it('loads the login page', () => {
    cy.location("pathname").should("include","/login");
    cy.contains('Email address');
    cy.contains('Password');
  });

  it('errors with no email or password', ()=>{
    cy.get("#username").should("have.value", "");
    cy.get("#password").should("have.value", "");
    cy.getByName("signin").click();
    cy.get(".alert-danger").should("exist").contains(errorText);
  });

  it('errors with no email', ()=> {
    cy.get("#username").should("have.value", "");
    cy.get("#password").type("password");
    cy.get("#password").should("have.value", "password");
    cy.getByName("signin").click();
    cy.get(".alert-danger").should("exist").contains(errorText);
  });

  it('errors with no password', ()=> {
    cy.get("#username").type("username@site.com");
    cy.get("#username").should("have.value", "username@site.com");
    cy.get("#password").should("have.value", "");
    cy.getByName("signin").click();
    cy.get(".alert-danger").should("exist").contains(errorText);
  });

  it('errors with incorrect details', () => {
    cy.get("#username").type("username@site.com");
    cy.get("#username").should("have.value", "username@site.com");
    cy.get("#password").type("badpassword");
    cy.get("#password").should("have.value", "badpassword");
    cy.getByName("signin").click();
    cy.get(".alert-danger").should("exist").contains(errorText);
  });

  it('errors with bad password but correct username', () => {
    cy.get("#username").type(goodUser);
    cy.get("#username").should("have.value", goodUser);
    cy.get("#password").type("badpassword");
    cy.get("#password").should("have.value", "badpassword");
    cy.getByName("signin").click();
    cy.get(".alert-danger").should("exist").contains(errorText);
  });

  it('errors with bad username but correct password', () => {
    cy.get("#username").type("bob@boom.com");
    cy.get("#username").should("have.value", "bob@boom.com");
    cy.get("#password").type(goodPassword);
    cy.get("#password").should("have.value", goodPassword);
    cy.getByName("signin").click();
    cy.get(".alert-danger").should("exist").contains(errorText);
  });

  it('logs in with correct details', () => {
    cy.get("#username").type(goodUser);
    cy.get("#username").should("have.value", goodUser);
    cy.get("#password").type(goodPassword);
    cy.get("#password").should("have.value", goodPassword);
    cy.getByName("signin").click();
    cy.location("pathname").should("not.include", "/login");
    cy.get(".user__link--logout").click();
    cy.location("pathname").should("include", "/login");
  });
});