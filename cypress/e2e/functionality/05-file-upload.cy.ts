import { goodPassword, goodUser } from "../../support/commands";

describe('Files upload', () => {
    beforeEach(() => {
        cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/file/');
    });

    it("should cancel upload", () => {
        cy.contains("Upload a file")
            .click();
        cy.contains("Cancel").click();
        cy.get(".modal").should("not.be.visible");
        cy.getDataTable()
            .find("tbody")
            .find("tr")
            .contains("There is no data available in this table")
    });

    it("Should error when uploading an invalid file", () => {
        cy.contains("Upload a file")
            .click();
        cy.get(".modal")
            .find("input[type='file']")
            .invoke('show')
            .selectFile("./cypress/fixtures/testfile.html", { force: true });
        cy.contains("Submit").click();
        cy.get(".alert-danger").should("be.visible").and("contain", "Files with extension");
    });

    it("Should upload a file", () => {
        cy.contains("Upload a file")
            .click();
        cy.get(".modal")
            .find("input[type='file']")
            .invoke('show')
            .selectFile("./cypress/fixtures/smiley.png", { force: true });
        cy.contains("Submit").click();
        cy.get(".modal").should("not.be.visible");
        cy.get(".alert-success").should("be.visible").and("contain", "File has been uploaded");
        cy.getDataTable()
            .find("tbody")
            .find("tr")
            .contains("smiley.png");
    });

    it("Should cancel deletion of a file", () => {
        cy.getDataTable()
            .find("tbody")
            .find("tr")
            .find("button")
            .click();
        cy.get(".modal")
            .should("be.visible", { timeout: 10000 })
            .find("button.btn-cancel")
            .eq(1)
            .click();
        cy.get(".modal").should("not.be.visible");
        cy.getDataTable()
            .find("tbody")
            .find("tr")
            .contains("smiley.png");
    });

    it("Should delete a file", () => {
        cy.getDataTable()
            .find("tbody")
            .find("tr")
            .find("button")
            .click();
        cy.get(".modal")
            .should("be.visible", { timeout: 10000 })
            .find("button.btn-danger")
            .click();
        cy.get(".modal").should("not.be.visible");
        cy.getDataTable()
            .find("tbody")
            .find("tr")
            .contains("There is no data available in this table");
    });
});