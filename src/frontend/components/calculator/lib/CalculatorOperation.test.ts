import {describe, it, expect} from '@jest/globals';
import {CalculatorOperation} from './CalculatorOperation';

describe('CalculatorOperation', () => {
    it('should create an instance with correct properties', () => {
        const operation = new CalculatorOperation('add', '+', ['+', 'plus'], (a, b) => a + b);
        expect(operation).toBeInstanceOf(CalculatorOperation);
        expect(operation['action']).toBe('add');
        expect(operation['label']).toBe('+');
        expect(operation['keypress']).toEqual(['+', 'plus']);
    });

    it('should render the HTML structure correctly', () => {
        const operation = new CalculatorOperation('subtract', '-', ['-', 'minus'], (a, b) => a - b);
        const rendered = operation.render();
        expect(rendered.length).toBe(1);
        expect(rendered.find('input').attr('id')).toBe('op_subtract');
        expect(rendered.find('label').text()).toBe('-');
    });

    it('should handle different operations', () => {
        const addOperation = new CalculatorOperation('add', '+', ['+', 'plus'], (a, b) => a + b);
        const subtractOperation = new CalculatorOperation('subtract', '-', ['-', 'minus'], (a, b) => a - b);

        expect(addOperation['operation'](2, 3)).toBe(5);
        expect(subtractOperation['operation'](5, 3)).toBe(2);
    });
});
