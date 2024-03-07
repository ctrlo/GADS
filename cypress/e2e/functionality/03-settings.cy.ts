/// <reference types="cypress" />
describe("settings tests", () => {
    const goodUser = "test@example.com"
    const goodPassword = "xyz123";

    beforeEach(() => {
        cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
    });

    afterEach(() => {
        cy.visit('http://localhost:3000/?did=1');
        cy.location("pathname").should("not.include", "/login");
        cy.getByTitle("Logout")
            .should("exist")
            .click();
        cy.location("pathname").should("include", "/login");
    });

    it("should navigate to the settings page and default settings items should be present", () => {
        const titles = ["Manage titles", "Manage Organisations", "welcome email", "personal details", "Logo and Security Marking", "audit logs"];
        const items = ["titles", "Organisation", "welcome email", "personal details", "default Security Marking", "audit log"];
        cy.get("a.nav__link--admin-settings")
            .should("exist")
            .click();
        for (let i = 0; i < titles.length; i++) {
            cy.mainBody()
                .find("a")
                .eq(i)
                .find("h4")
                .find("span")
                .contains(titles[i]);
            cy.mainBody()
                .find("a")
                .eq(i)
                .find("p")
                .contains(items[i]);
        }
    });

    context("manage titles", () => {
        beforeEach(()=>{
            cy.visit('http://localhost:3000/settings');
        });

        it("should navigate to the manage titles page", () => {
            cy.mainBody()
                .find("a")
                .eq(0)
                .click();
            cy.location("pathname").should("include", "/title_overview");
            cy.mainHeader()
                .find(".btn__title")
                .should("exist")
                .contains("Manage titles");
            cy.mainHeader()
                .find(".content-block__intro")
                .should("exist")
                .contains("In this window you can list the titles that you want to assign users to.");
        });

        it("can cancel creation of a new title", () => {
            cy.mainBody()
                .find("a")
                .eq(0)
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("No titles available");
            cy.mainHeader()
                .find(".btn-default")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/title_add");
            cy.mainBody()
                .find("input#name")
                .type("test title");
            cy.mainBody()
                .find("a.btn-cancel")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/title_overview");
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .should("not.contain", "test title");
        });

        it("Can create a new title", () => {
            cy.mainBody()
                .find("a")
                .eq(0)
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("No titles available");
            cy.mainHeader()
                .find(".btn-default")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/title_add");
            cy.mainBody()
                .find("input#name")
                .type("test title");
            cy.mainBody()
                .find("button[type=submit]")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/title_overview");
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("test title");
        });

        it("Can delete a title", () => {
            cy.mainBody()
                .find("a")
                .eq(0)
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("test title");
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .find("button.btn-delete")
                .click();
            cy.get(".modal")
                .should("be.visible")
                .find("button[type=submit].btn-danger")
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("No titles available");
        });
    });

    context("manage organisations", () => {
        beforeEach(()=>{
            cy.visit('http://localhost:3000/settings');
        })

        it("should navigate to the manage organisations page", () => {
            cy.mainBody()
                .find("a")
                .eq(1)
                .click();
            cy.location("pathname").should("include", "/organisation_overview");
            cy.mainHeader()
                .find(".btn__title")
                .should("exist")
                .contains("Manage organisations"); // <--inconsistent casing
            cy.mainHeader()
                .find(".content-block__intro")
                .should("exist")
                .contains("In this window you can list the parts of the organisation that you want to assign users to.");
        });

        it("can cancel creation of a new organisation", () => {
            cy.mainBody()
                .find("a")
                .eq(1)
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("No organisations available");
            cy.mainHeader()
                .find(".btn-default")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/organisation_add");
            cy.mainBody()
                .find("input#name")
                .type("test organisation");
            cy.mainBody()
                .find("a.btn-cancel")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/organisation_overview");
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .should("not.contain", "test organisation");
        });

        it("Can create a new organisation", () => {
            cy.mainBody()
                .find("a")
                .eq(1)
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("No organisations available");
            cy.mainHeader()
                .find(".btn-default")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/organisation_add");
            cy.mainBody()
                .find("input#name")
                .type("test organisation");
            cy.mainBody()
                .find("button[type=submit]")
                .should("exist")
                .click();
            cy.location("pathname").should("include", "/organisation_overview");
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("test organisation");
        });

        it("Can delete a organisation", () => {
            cy.mainBody()
                .find("a")
                .eq(1)
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("test organisation");
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .find("button.btn-delete")
                .click();
            cy.get(".modal")
                .should("be.visible")
                .find("button[type=submit].btn-danger")
                .click();
            cy.getDataTable()
                .find("tbody")
                .find("tr")
                .contains("No organisations available");
        });
    });
});
