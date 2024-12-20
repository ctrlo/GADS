import "testing/globals.definitions";
import InputComponent from './component';
import { describe, expect, it } from '@jest/globals';

describe('Input Components', () => {
    const componentMap: { [key: string]: string } = {
        'password': 'input--password',
        'logo': 'input--logo',
        'document': 'input--document',
        'file': 'input--file',
        'date': 'input--datepicker',
        'autocomplete': 'input--autocomplete'
    };

    for (const [key, value] of Object.entries(componentMap)) {
        it(`should render a ${key} component`, () => {
            const inputComponent = document.createElement('input');
            inputComponent.classList.add(value);
            const component = new InputComponent(inputComponent);
            expect(component).toBeDefined();
            expect(component.linkedComponent?.type).toBe(key);
            expect(component.isValidatationEnabled).toBeFalsy();
        });
    }

    for (const [key, value] of Object.entries(componentMap)) {
        it(`should render a ${key} component with validation`, () => {
            const inputComponent = document.createElement('input');
            inputComponent.classList.add(value);
            inputComponent.classList.add('input--required');
            const component = new InputComponent(inputComponent);
            expect(component).toBeDefined();
            expect(component.linkedComponent?.type).toBe(key);
            expect(component.isValidatationEnabled).toBeTruthy();
        });
    }

    it('should initialize a required input', () => {
        const inputComponent = document.createElement('input');
        inputComponent.classList.add('input--required');
        const component = new InputComponent(inputComponent);
        expect(component).toBeDefined();
        expect(component.isValidatationEnabled).toBeTruthy();
    });
});