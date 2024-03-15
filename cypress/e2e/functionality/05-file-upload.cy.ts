import { goodPassword, goodUser } from "../../support/commands";

describe('Files upload', () => {
    beforeEach(() => {
        cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/file/');
    });

    it("should cancel upload", () => {
        cy.get("button.btn-default")
            .eq(1)
            .click();
        cy.get(".btn-cancel")
            .eq(0)
            .click();
        cy.get(".modal").should("not.be.visible");
        cy.getDataTable().find("tbody").find("tr").contains("There is no data available in this table")
    });
});