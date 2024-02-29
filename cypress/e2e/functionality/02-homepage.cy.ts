/// <reference types="cypress" />

describe('Login Tests', () => {
  const goodUser = "test@example.com"
  const goodPassword = "xyz123";

  context("Basic Home Dashboard Tests", () => {
    it('Displays the home page correctly', () => {
      cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
      cy.get("li.list__item").eq(0)
        .should("exist")
        .contains("Home dashboard (shared)")
        .should("have.class", "link--active");
      cy.get("li.list__item").eq(1)
        .should("exist")
        .contains("Home dashboard (personal)")
        .should("not.have.class", "link--active");
    });

    it('Should navigate to the personal dashboard', () => {
      cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
      cy.get("li.list__item").eq(1)
        .should("exist")
        .should("not.have.class", "link--active")
        .click();
    });

    it('Should navigate to the shared dashboard', () => {
      cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
      cy.get("li.list__item").eq(0)
        .should("exist")
        .should("not.have.class", "link--active")
        .click();
    });

    context("Dashboard Tests", () => {
      context("Shared Dashboard", () => {
        it('Should cancel creation of a shared dashboard widget', () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
          cy.get(".ld-footer-container")
            .find("button")
            .eq(1)
            .click();
          cy.get(".ld-footer-container")
            .find(".dropdown__menu")
            .find("a")
            .eq(1)
            .click();
          cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
          cy.get(".ld-widget").should("have.length", 0);
        });

        it("Should create a shared dashboard widget", () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
          cy.get(".ld-footer-container")
            .find("button")
            .eq(1)
            .click();
          cy.get(".ld-footer-container")
            .find(".dropdown__menu")
            .find("a")
            .eq(1)
            .click();
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']", { timeout: 10000 })
            .should("be.visible");
          cy.get("[aria-label='Edit Modal']")
            .find(".modal-footer__right")
            .find("button.btn-default").click();
          cy.get(".ld-widget").should("have.length", 1);
          cy.get(".ld-widget").find("div").contains("This is a new notice widget - click edit to update the contents");
        });

        it("Should edit a shared dashboard widget", () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
          cy.get(".ld-widget").find(".ld-edit-button").click();
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']", { timeout: 10000 })
            .should("be.visible");
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']")
            .type("With a new title");
          cy.get("[aria-label='Edit Modal']")
            .find(".modal-footer__right")
            .find("button.btn-default").click();
          cy.get(".ld-widget").find("h4").contains("With a new title");
        });

        it("Should delete a shared dashboard widget", () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
          cy.get(".ld-widget").find(".ld-edit-button").click();
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']", { timeout: 10000 })
            .should("be.visible");
          cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
          cy.get(".ld-widget").should("have.length", 0);
        });
      });

      context.only("Personal Dashboard", () => {
        it('Should cancel creation of a personal dashboard widget', () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1')
            .get("a.link--primary").click();
          cy.get(".ld-footer-container")
            .find("button")
            .eq(1)
            .click();
          cy.get(".ld-footer-container")
            .find(".dropdown__menu")
            .find("a")
            .eq(1)
            .click();
          cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
          cy.get(".ld-widget").should("have.length", 0);
        });

        it("Should create a shared dashboard widget", () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1')
            .get("a.link--primary").click();
          cy.get(".ld-footer-container")
            .find("button")
            .eq(1)
            .click();
          cy.get(".ld-footer-container")
            .find(".dropdown__menu")
            .find("a")
            .eq(1)
            .click();
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']", { timeout: 10000 })
            .should("be.visible");
          cy.get("[aria-label='Edit Modal']")
            .find(".modal-footer__right")
            .find("button.btn-default").click();
          cy.get(".ld-widget").should("have.length", 1);
          cy.get(".ld-widget").find("div").contains("This is a new notice widget - click edit to update the contents");
        });

        it("Should edit a shared dashboard widget", () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1')
            .get("a.link--primary").click();
          cy.get(".ld-widget").find(".ld-edit-button").click();
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']", { timeout: 10000 })
            .should("be.visible");
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']")
            .type("With a new title");
          cy.get("[aria-label='Edit Modal']")
            .find(".modal-footer__right")
            .find("button.btn-default").click();
          cy.get(".ld-widget").find("h4").contains("With a new title");
        });

        it("Should delete a shared dashboard widget", () => {
          cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1')
            .get("a.link--primary").click();
          cy.get(".ld-widget").find(".ld-edit-button").click();
          cy.get("[aria-label='Edit Modal']")
            .find("input[name='title']", { timeout: 10000 })
            .should("be.visible");
          cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
          cy.get(".ld-widget").should("have.length", 0);
        });
      });
    });

    it('Should logout', () => {
      cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
      cy.location("pathname").should("not.include", "/login");
      cy.getByTitle("Logout")
        .should("exist")
        .click();
      cy.location("pathname").should("include", "/login");
    });
  });
});