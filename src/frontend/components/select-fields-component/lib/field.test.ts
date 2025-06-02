import { describe, it, expect } from '@jest/globals';
import { Field } from './field';

describe('Field Tests', () => {
    it('should create a Field instance from an HTMLInputElement', () => {
        const input = document.createElement('input');
        input.type = 'checkbox';
        input.value = '1';
        input.id = 'field1';
        const label = document.createElement('label');
        label.setAttribute('for', 'field1');
        label.textContent = 'Test Field';
        document.body.appendChild(input);
        document.body.appendChild(label);

        const field = Field.createField(input);
        expect(field).toBeInstanceOf(Field);
        expect(field.id).toBe(1);
        expect(field.label).toBe('Test Field');
        expect(field.checked).toBe(false);

        // Clean up
        document.body.removeChild(input);
        document.body.removeChild(label);
    });

    it('should throw an error if field ID is not defined or empty', () => {
        const input = document.createElement('input');
        input.type = 'checkbox';
        input.value = '';
        
        expect(() => Field.createField(input)).toThrow('Field ID is not defined or empty');
    });

    it('should throw an error if field label is not defined or empty', () => {
        const input = document.createElement('input');
        input.type = 'checkbox';
        input.value = '2';
        input.id = 'field2';
        
        expect(() => Field.createField(input)).toThrow('Field label is not defined or empty');
    });
});
