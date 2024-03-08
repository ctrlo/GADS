/// <reference types="cypress" />

describe('Group Test', () => {
    const goodUser = "test@example.com";
    const goodPassword = "xyz123";

    beforeEach(() => {
        // Login
        cy.visit('http://localhost:3000');
        cy.get("#username").type(goodUser);
        cy.get("#password").type(goodPassword);
        cy.getByName("signin").click();
        cy.location("pathname").should("not.include", "/login");

        // Navigate to group_overview page
        cy.visit('http://localhost:3000/group_overview/');
        cy.location("pathname").should("include", "/group_overview/");
    });

    it('should create a group successfully', () => {
        const groupName = 'long temporary value to test special char\'<\a><;[{END\"';

        cy.contains('a', 'Add group').click();
        cy.location("pathname").should("include", "/group_add/");
        cy.get('#name').type(groupName);
        cy.contains('button', 'Save').click();
        cy.get('div.alert.alert-success')
            .should('be.visible')
            .and('contain', 'Group has been created successfully');
    });

    it('should access a group and cancel', () => {
        const groupName = 'long temporary value to test special char\'<\a><;[{END\"';
        cy.contains('a', groupName).click();
        cy.location("pathname").should("include", "group_edit/");
        cy.contains('a.btn-cancel', 'Cancel').click();
    });

    it('should delete a group and cancel', () => {
        const groupName = 'long temporary value to test special char\'<\a><;[{END\"';
        cy.contains('tr', groupName).within(() => {
            cy.get('.btn-delete').click();
        });
        cy.get('.modal-footer__left').find('.btn-cancel').click();
        cy.contains('a', groupName).should('exist');
        cy.location("pathname").should("include", "/group_overview/");
    });

    it('should edit and delete a group', () => {
        const groupName = 'long temporary value to test special char\'<\a><;[{END\"';
        cy.contains('a', groupName).click();
        cy.location("pathname").should("include", "group_edit/");
        cy.get('#name').type('to Be deleted');
        cy.contains('button', 'Save').click();
        cy.location("pathname").should("include", "/group_overview/");
        cy.contains('to Be deleted').click();
        cy.location("pathname").should("include", "group_edit/");
        cy.contains('.btn__title', 'Delete group').click();
        cy.contains('button.btn.btn-danger', 'Delete').click();
        cy.location("pathname").should("include", "/group_overview/");
        cy.get('div.alert.alert-success')
            .should('be.visible')
            .and('contain', 'The group has been deleted successfully');
        cy.contains('to Be deleted').should('not.exist');
    });

    it('should check group existence in other locations', () => {
        cy.visit('http://localhost:3000/user/1');
        cy.location("pathname").should("include", "user/1");
        cy.contains('long temporary value').should('not.exist');
    });
});

