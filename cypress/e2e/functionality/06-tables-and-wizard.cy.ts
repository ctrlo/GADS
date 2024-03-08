 /// <reference types="cypress" />

describe('Another Test Suite', () => {
    const goodUser = "test@example.com";
    const goodPassword = "xyz123";

    beforeEach(() => {
        // Login
        cy.loginAndGoTo(goodUser,goodPassword,'http://localhost:3000/table');
        cy.location("pathname").should("include", "/table");
    });

//attempt save with incorrect (fails)
//    it('should fail to save new table with  invalid shortname ', () => {
//        cy.get('[data-target="#newTableModal"]').click();
//        cy.get('#shortName').type('This value wont $4v£');
//        cy.get("#name").type("table to fail");
//        cy.get('.btn-js-next').eq(0).click();
//        cy.get('.btn-js-save').eq(0).click();
//        cy.get('div.alert.alert-danger')
//            .should('be.visible')
//            .and('contain', 'Invalid short name for table');

//     });

    it('should save a new table successfully', () => {
        cy.get('[data-target="#newTableModal"]').click();
        cy.get('#shortName').type('1-test_table');
        cy.get("#name").type("1-test-table");
        cy.get('.btn-js-next').eq(0).click();
        cy.get('.btn-js-save').eq(0).click();
        cy.location("pathname").should("include", "/table");
        cy.contains('1-test-table').should('exist');
    });


    it('table is accessible', () => {
        cy.contains('tr', '1-test-table')
            .contains('a', 'Edit table')
            .click();
        cy.location("pathname").should("include", "1-test_table/edit");
    });

    it('table can be deleted', () => {
        cy.visit('http://localhost:3000/1-test_table/edit');
        cy.location("pathname").should("include", "1-test_table/edit");
        cy.contains('button', 'Delete table').click();
        cy.get('.modal-dialog').within(() => {
            cy.contains('h3.modal-title', 'Delete - 1-test-table').should('exist');
        });
        cy.get('.modal-footer__right').contains('button', 'Delete').click();
        cy.location("pathname").should("include", "/table");
        cy.contains('.alert.alert-success', 'The table has been deleted successfully').should('exist');
        cy.contains('1-test-table').should('not.exist');
    });

    it('Deleted table no longer accessible', () => {
        cy.request({
            url: 'http://localhost:3000/1-test_table/edit',
            failOnStatusCode: false // Prevent Cypress from failing the test on non-2xx status codes
        }).then((response) => {
            // Check if the response status is either 302 or 404
            expect(response.status).to.be.oneOf([302, 404]);
        });
    });
});
