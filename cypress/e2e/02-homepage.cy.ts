describe('Login Tests', () => {
  const errorText = "The username or password was not recognised";
  const goodUser = "test@example.com"
  const goodPassword = "xyz123";

  beforeEach(() => {
    cy.visit('http://localhost:3000');
    cy.get("#username").type(goodUser);
    cy.get("#username").should("have.value", goodUser);
    cy.get("#password").type(goodPassword);
    cy.get("#password").should("have.value", goodPassword);
    cy.getByName("signin").click();
    cy.location("pathname").should("not.include", "/login");
  })

  context("Basic Home Dashboard Tests", () => {
    it('Displays the home page correctly', () => {
      cy.get("#username").should("not.exist");
      cy.get("#password").should("not.exist");
      cy.visit('http://localhost:3000/?did=1');
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
      cy.get("#username").should("not.exist");
      cy.get("#password").should("not.exist");
      cy.visit('http://localhost:3000');
      cy.get("li.list__item").eq(1)
        .should("exist")
        .should("not.have.class", "link--active")
        .click();
    });

    it('Should navigate to the shared dashboard', () => {
      cy.get("#username").should("not.exist");
      cy.get("#password").should("not.exist");
      cy.visit('http://localhost:3000');
      cy.get("li.list__item").eq(0)
        .should("exist")
        .should("not.have.class", "link--active")
        .click();
    });

    it('Should logout',()=>{
      cy.location("pathname").should("not.include", "/login");
      cy.getByTitle("Logout")
        .should("exist")
        .click();
      cy.location("pathname").should("include", "/login");
    });
  });
});