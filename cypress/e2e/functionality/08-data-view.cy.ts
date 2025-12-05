import "../../support/commands";
import { goodPassword, goodUser } from "../../support/constants"

// This test suite is just to ensure the data table menu items are present and correct
describe('Data table', () => {
  // This section is for the admin user in order to check all permissions work and can be applied correctly
  describe('Admin user', () => {
    beforeEach(() => {
      cy.loginAndGoTo(goodUser, goodPassword, 'http://localhost:3000/table1/data');
    });

    it('All expected tabs and title are present', () => {
      cy.get('.table-header__title').should('exist').contains('WebDriverTestSheet');
      const tb = cy.get('.table-header-bottom');
      tb.should('exist');
      const tabs = tb.find('ul').find('li');
      tabs.should('exist').should('have.length', 4);
      const tabContent = ['Records', 'Dashboard', 'Edit table', 'Reports'];
      tabs.each((tab, idx) => {
        cy.wrap(tab).should('exist').contains(tabContent[idx]);
      });
    });

    it('Has the correct items in the left navigation', () => {
      const nl = cy.get('.content-block__navigation-left');
      nl.should('exist');
      nl.find('.dropdown').should('exist').contains('Current view');
      const vt = cy.get('.content-block__navigation-left').find('ul').find('li').eq(1);
      vt.should('exist');
      vt.find('ul').find('li').should('exist').should('have.length', 3);
      const viewTypes = ['Table', 'Graph', 'Timeline'];
      cy.get('.content-block__navigation-left').find('ul').find('li').eq(1).find('ul').find('li').each((li, idx) => {
        cy.wrap(li).should('exist').contains(viewTypes[idx]);
      });
    });

    it('Has the correct items in the right navigation', () => {
      // Add the user to the group
      cy.addUserToGroup('test@example.com', 'basic', 'http://localhost:3000/table1/data');
      // Set all table permissions
      cy.setAllTablePermissions();
      // Check everything is as expected
      cy.get('.content-block__navigation-right').should('exist');
      cy.get('.content-block__navigation-right').find('.dropdown').should('exist').should('have.length', 2);
      const dropdowns = ['Manage views', 'Actions'];
      cy.get('.content-block__navigation-right').find('.dropdown').each((dropdown,idx)=>{
        cy.wrap(dropdown).should('exist').contains(dropdowns[idx]);
      });
    });

    it('Has the correct items in the right navigation dropdowns', ()=>{
      const dropdownData = {
        'Manage views': ['Add a view', 'Manage views of another user', 'Historic view'],
        'Actions': ['Import records','Delete all records in this view','Update all records in this view','Clone all records in this view','Download records','Manage deleted records','Field Data Purge']
      }
      for(const key in dropdownData) {
        cy.get('.content-block__navigation-right').find('.dropdown').contains(key).click();
        cy.get('.dropdown-menu').should('exist');
        cy.get('.content-block__navigation-right').find('.dropdown').contains(key).parent().find('li').each((li, idx) => {
          cy.wrap(li).should('exist').contains(dropdownData[key][idx]);
        });
        cy.get('.content-block__navigation-right').find('.dropdown').contains(key).click();
      }
    });
  });
});