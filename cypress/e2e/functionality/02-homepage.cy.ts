import { goodPassword, goodUser } from "../../support/constants";

describe('Dashboard Tests', () => {
  const bigLipsum = `Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque accumsan, sem et vulputate imperdiet, enim ipsum rhoncus massa, sit amet pellentesque lacus urna sit amet enim. In tristique mollis tincidunt. Sed eget ligula metus. Integer sodales placerat erat. Aliquam erat volutpat. Curabitur varius lacinia diam fringilla efficitur. Sed euismod purus vel turpis molestie, ac fringilla nisi vestibulum. Maecenas ullamcorper ornare dui sodales gravida. Donec maximus egestas eleifend. Etiam in ultrices ante. Duis quis volutpat turpis. Nulla dignissim ornare aliquet.
Fusce interdum gravida est, sit amet vehicula nisi suscipit at. Pellentesque nec fermentum leo, in vehicula nulla. Nam dapibus ultricies tortor in maximus. Donec enim velit, molestie nec feugiat sed, posuere non ex. Nulla pellentesque gravida feugiat. Sed ornare purus vel libero semper aliquet. Nulla rutrum nunc sed vulputate gravida. Cras lobortis, lacus non tincidunt suscipit, leo quam vehicula libero, in vehicula diam justo ac est.
Mauris tempus, mi nec sodales semper, metus neque blandit sem, non scelerisque nunc libero eu augue. Cras ornare ut lectus in mattis. Quisque magna elit, efficitur nec dolor sed, semper dictum nunc. Cras ultricies, augue eget interdum aliquam, quam ex blandit sem, nec sollicitudin ex elit non mauris. Fusce dui justo, feugiat id lacus sit amet, pulvinar tristique felis. Etiam rhoncus ex ut congue aliquet. Sed at felis eget neque rhoncus malesuada. Aliquam commodo condimentum massa, sed volutpat nibh congue et. Maecenas blandit massa sed nisl pulvinar, vitae consectetur tortor placerat. Nulla laoreet diam ipsum, sit amet consectetur sem condimentum quis. Nullam et justo sem. Sed et sapien tempus, scelerisque nisl ac, pretium arcu.`

  beforeEach(() => {
    cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
  })

  afterEach(() => {
    cy.visit('http://localhost:3000/?did=1');
    cy.location("pathname").should("not.include", "/login");
    cy.getByTitle("Logout")
      .should("exist")
      .click();
    cy.location("pathname").should("include", "/login");
  })

  it('Displays the home page correctly', () => {
    cy.get("a.nav-link").eq(0)
      .should("exist")
      .should("have.class", "active")
      .contains("Home dashboard (shared)");
    cy.get("a.nav-link").eq(1)
      .should("exist")
      .should("not.have.class", "active")
      .contains("Home dashboard (personal)");
  });

  it('Should navigate to the personal dashboard', () => {
    cy.get("a.nav-link").eq(1)
      .should("exist")
      .should("not.have.class", "active")
      .click();
    cy.get("a.nav-link").eq(1)
      .should("exist")
      .should("have.class", "active")
      .contains("Home dashboard (personal)");
  });

  it('Should navigate to the shared dashboard', () => {
    cy.get("a.nav-link").eq(1)
      .click();
    cy.get("a.nav-link").eq(0)
      .should("exist")
      .should("not.have.class", "active")
      .click();
    cy.get("a.nav-link").eq(0)
      .should("exist")
      .should("have.class", "active")
      .contains("Home dashboard (shared)");
  });

  context("Shared Dashboard", () => {
    it('Should cancel creation of a shared dashboard widget', () => {
      cy.get(".ld-footer-container")
        .find("button")
        .eq(1)
        .click();
      cy.get(".ld-footer-container")
        .find(".dropdown-menu.show")
        .find("a")
        .eq(0)
        .click();
      cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
      cy.get(".ld-widget").should("have.length", 0);
    });

    it("Should create a shared dashboard widget", () => {
      cy.get(".ld-footer-container")
        .find("button")
        .eq(1)
        .click();
      cy.get(".ld-footer-container")
        .find(".dropdown-menu.show")
        .find("a")
        .eq(0)
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

    it("Should edit a shared dashboard widget with a lot of text", () => {
      cy.get(".ld-widget").find(".ld-edit-button").click();
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']", { timeout: 10000 })
        .should("be.visible");
      cy.get("[aria-label='Edit Modal']")
        .find("div[contenteditable='true']")
        .clear()
        .type(bigLipsum);
      cy.get("[aria-label='Edit Modal']")
        .find(".modal-footer__right")
        .find("button.btn-default").click();
    });

    it("Should delete a shared dashboard widget", () => {
      cy.get(".ld-widget").find(".ld-edit-button").click();
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']", { timeout: 10000 })
        .should("be.visible");
      cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
      cy.get(".ld-widget").should("have.length", 0);
    });
  });

  context("Personal Dashboard", () => {
    it('Should cancel creation of a personal dashboard widget', () => {
      cy.get("a.nav-link").eq(1).click();
      cy.get(".ld-footer-container")
        .find("button")
        .eq(1)
        .click();
      cy.get(".ld-footer-container")
        .find(".dropdown-menu.show")
        .find("a")
        .eq(0)
        .click();
      cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
      cy.get(".ld-widget").should("have.length", 1);
    });

    it("Should create a personal dashboard widget", () => {
      cy.get("a.nav-link").eq(1).click();
      cy.get(".ld-footer-container")
        .find("button")
        .eq(1)
        .click();
      cy.get(".ld-footer-container")
        .find(".dropdown-menu.show")
        .find("a")
        .eq(0)
        .click();
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']", { timeout: 10000 })
        .should("be.visible");
      cy.get("[aria-label='Edit Modal']")
        .find(".modal-footer__right")
        .find("button.btn-default").click();
      cy.get(".ld-widget").should("have.length", 2);
      cy.get(".ld-widget").eq(1).find("div").contains("This is a new notice widget - click edit to update the contents");
    });

    it("Should edit a personal dashboard widget", () => {
      cy.get("a.nav-link").eq(1).click();
      cy.get(".ld-widget").eq(1).find(".ld-edit-button").click();
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']", { timeout: 10000 })
        .should("be.visible");
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']")
        .type("With a new title");
      cy.get("[aria-label='Edit Modal']")
        .find(".modal-footer__right")
        .find("button.btn-default").click();
      cy.get(".ld-widget").eq(1).find("h4").contains("With a new title");
    });

    it("Should edit a personal dashboard widget with a lot of text", () => {
      cy.get("a.nav-link").eq(1).click();
      cy.get(".ld-widget").eq(1).find(".ld-edit-button").click();
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']", { timeout: 10000 })
        .should("be.visible");
      cy.get("[aria-label='Edit Modal']")
        .find("div[contenteditable='true']")
        .clear()
        .type(bigLipsum);
      cy.get("[aria-label='Edit Modal']")
        .find(".modal-footer__right")
        .find("button.btn-default").click();
    });

    it("Should delete a personal dashboard widget", () => {
      cy.get("a.nav-link").eq(1).click();
      cy.get(".ld-widget").eq(1).find(".ld-edit-button").click();
      cy.get("[aria-label='Edit Modal']")
        .find("input[name='title']", { timeout: 10000 })
        .should("be.visible");
      cy.get("[aria-label='Edit Modal']").find("button.btn-cancel").click();
      cy.get(".ld-widget").should("have.length", 1);
    });
  });
});
