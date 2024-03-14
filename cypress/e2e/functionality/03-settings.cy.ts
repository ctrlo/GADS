/// <reference types="cypress" />
describe("settings tests", () => {
    const goodUser = "test@example.com"
    const goodPassword = "xyz123";

    beforeEach(() => {
        cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/?did=1');
    });

    afterEach(() => {
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
        beforeEach(() => {
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

        it("Can cancel deletion of a title", () => {
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
                .find("button.btn-cancel")
                .click();
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
        beforeEach(() => {
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

        it("Can cancel deletion of an organisation", () => {
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
                .find("button.btn-cancel")
                .click();
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

    context("welcome email", () => {
        beforeEach(() => {
            cy.visit('http://localhost:3000/settings');
        })

        it("should navigate to the welcome email page", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.location("pathname").should("include", "/default_welcome_email");
            cy.mainHeader()
                .find(".btn__title")
                .should("exist")
                .contains("Default welcome email");
            cy.mainHeader()
                .find(".content-block__intro")
                .should("exist")
                .contains("On this page you can define your welcome email to new users of your system.");
        });

        it("Should be able to set the System Name", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .type("Test System Name");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name");
        });

        it("Should be able to clear the System Name", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .clear()
                .should("have.value", "");
        });

        it("Should be able to set the Welcome Email Subject", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .type("Test Subject");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject");
        });

        it("Should be able to clear the Welcome Email Subject", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .clear()
                .should("have.value", "");
        });

        it("Should be able to set the Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .type("Test Body\n\nTest Body");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body");
        });

        it("Should be able to clear the Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "");
        });

        it("Should be able to set both the System Name, and Welcome Email Subject", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .type("Test System Name");
            cy.mainBody()
                .find("input#email_welcome_subject")
                .type("Test Subject");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name");
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject");
        });

        it("Should be able to clear both the System Name, and Welcome Email Subject", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name")
                .clear();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "");
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "");
        });

        it("Should be able to set both the System Name, and Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .type("Test System Name");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .type("Test Body\n\nTest Body");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body");
        });

        it("Should be able to clear both the System Name, and Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name")
                .clear();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "");
        });

        it("Should be able to set both the Welcome Email Subject, and Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .type("Test Subject");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .type("Test Body\n\nTest Body");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body");
        });

        it("Should be able to clear both the Welcome Email Subject, and Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject")
                .clear();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "");
        });

        it("Should be able to set the System Name, Welcome Email Subject, and Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .type("Test System Name");
            cy.mainBody()
                .find("input#email_welcome_subject")
                .type("Test Subject");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .type("Test Body\n\nTest Body");
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name");
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body");
        });

        it("Should be able to clear the System Name, Welcome Email Subject, and Welcome Email Text", () => {
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "Test System Name")
                .clear();
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "Test Subject")
                .clear();
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "Test Body\n\nTest Body")
                .clear();
            cy.mainBody()
                .find("button[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(2)
                .click();
            cy.mainBody()
                .find("input#name")
                .should("have.value", "");
            cy.mainBody()
                .find("input#email_welcome_subject")
                .should("have.value", "");
            cy.mainBody()
                .find("textarea#email_welcome_text")
                .should("have.value", "");
        });
    });

    context("personal details", () => {
        beforeEach(() => {
            cy.visit('http://localhost:3000/settings');
        });

        it("should navigate to the personal details page", () => {
            cy.mainBody()
                .find("a")
                .eq(3)
                .click();
            cy.location("pathname").should("include", "/user_editable_personal_details");
            cy.mainHeader()
                .find(".content-block__intro")
                .should("exist")
                .contains("On this page you can define which personal details the users are allowed to edit.");
        });

        it("Should allow cancellation of editing details", () => {
            cy.mainBody()
                .find("a")
                .eq(3)
                .click();
            cy.mainBody()
                .get("#firstname-label")
                .click();
            cy.mainBody()
                .get("#email-label")
                .click();
            cy.mainBody()
                .get(".btn-cancel")
                .click();
            cy.mainBody()
                .find("a")
                .eq(3)
                .click();
            cy.mainBody()
                .get('#firstname')
                .should('have.attr', 'checked');
            cy.mainBody()
                .get('#email')
                .should('have.attr', 'checked');
        });

        it("Should allow editing details", () => {
            cy.mainBody()
                .find("a")
                .eq(3)
                .click();
            cy.mainBody()
                .get("#firstname-label")
                .click();
            cy.mainBody()
                .get("#email-label")
                .click();
            cy.mainBody()
                .get("[type=submit]")
                .click();
            cy.mainBody()
                .find("a")
                .eq(3)
                .click();
            cy.mainBody()
                .get('#firstname')
                .should('not.have.attr', 'checked');
            cy.mainBody()
                .get('#email')
                .should('not.have.attr', 'checked');
        });

        after(() => {
            cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/settings');
            cy.mainBody()
                .find("a")
                .eq(3)
                .click();
            cy.mainBody()
                .get("#firstname-label")
                .click();
            cy.mainBody()
                .get("#email-label")
                .click();
            cy.mainBody()
                .get("[type=submit]")
                .click();
        });
    });

    context("Logo and Security Marking", () => {
        beforeEach(() => {
            cy.visit('http://localhost:3000/settings');
        });

        it("Should navigate to the Logo and Security Marking page", () => {
            cy.mainBody()
                .find("a")
                .eq(4)
                .click();
            cy.location("pathname").should("include", "/report_defaults");
            cy.mainHeader()
                .find(".content-block__intro")
                .should("exist")
                .contains("In this window you can set the default values for reports.");
        });

        it("Should have the default security marking value", () => {
            cy.mainBody()
                .find("a")
                .eq(4)
                .click();
            cy.mainBody()
                .getByName("security_marking")
                .should("have.value", "Example Application");
        })

        it("Should be able to change the default security marking value", () => {
            cy.mainBody()
                .find("a")
                .eq(4)
                .click();
            cy.mainBody()
                .getByName("security_marking")
                .should("have.value", "Example Application");
            cy.getByName("security_marking")
                .clear()
                .type("Test Application");
            cy.mainBody()
                .get("button[type=submit]")
                .click();
            cy.visit('http://localhost:3000/settings');
            cy.mainBody()
                .find("a")
                .eq(4)
                .click();
            cy.mainBody()
                .getByName("security_marking")
                .should("have.value", "Test Application");
        });

        it("Should be able to clear the default security marking value", () => {
            cy.mainBody()
                .find("a")
                .eq(4)
                .click();
            cy.mainBody()
                .getByName("security_marking")
                .should("have.value", "Test Application")
                .clear();
            cy.mainBody()
                .get("button[type=submit]")
                .click();
            cy.visit('http://localhost:3000/settings');
            cy.mainBody()
                .find("a")
                .eq(4)
                .click();
            cy.mainBody()
                .getByName("security_marking")
                .should("have.value", "Example Application");
        });
    });

    context("audit logs", () => {
        beforeEach(() => {
            cy.visit('http://localhost:3000/settings');
        });

        it("Should navigate to the audit logs page", () => {
            cy.mainBody()
                .find("a")
                .eq(5)
                .click();
            cy.location("pathname").should("include", "/audit");
            cy.mainHeader()
                .find(".content-block__intro")
                .should("exist")
                .contains("In this window you can view your system audit log.");
        });
    });
});
