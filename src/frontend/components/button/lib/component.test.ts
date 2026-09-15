import { describe, it, expect } from '@jest/globals';
import ButtonComponent from './component';

describe('Button Component - error with querybuilder in jest', () => {
    it('should not create a button with an invalid type', () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn');
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses).toStrictEqual([]);
    });

    it('should not create a button with an invalid type but with valid class prefix', () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn-js-nope');
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses).toStrictEqual([]);
    });

    it.each([
        ['report', 'btn-js-report'],
        ['more info', 'btn-js-more-info'],
        ['delete', 'btn-js-delete'],
        // ['submit field', 'btn-js-submit-field'], - JQuery not loading for this test, so this button is not being created
        ['add all fields', 'btn-js-toggle-all-fields'],
        ['submit draft record', 'btn-js-submit-draft-record'],
        ['submit record', 'btn-js-submit-record'],
        // ['save view', 'btn-js-save-view'], - JQuery not loading for this test, so this button is not being created
        ['show blank', 'btn-js-show-blank'],
        ['curval remove', 'btn-js-curval-remove'],
        ['remove unload', 'btn-js-remove-unload']
    ]) (`Should create a %s button`, (name, className) => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add(className);
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses.includes(className)).toBeTruthy();
    });

    it('Should create a composite button', () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn-js-report');
        buttonElement.classList.add('btn-js-remove-unload');
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses.includes('btn-js-report')).toBeTruthy();
        expect(button.linkedClasses.includes('btn-js-remove-unload')).toBeTruthy();
    });
});
