import { describe, it, expect } from '@jest/globals';
import * as utils from './util';

describe('Util Tests', () => {
    const testValues = [{
        value: '',
        expected: true
    }, {
        value: ' ',
        expected: true
    }, {
        value: null,
        expected: false
    }, {
        value: undefined,
        expected: false
    }, {
        value: 'test',
        expected: true
    }]

    for (const { value, expected } of testValues) {
        it(`should return ${expected} for ${value} when using isDefined`, () => {
            const result = utils.isDefined(value);
            expect(result).toBe(expected);
        });
    }

    for(const { value, expected } of testValues) {
        it(`should return ${expected} for ${value} when using isString`, () => {
            const result = utils.isString(value);
            expect(result).toBe(expected);
        });
    }

    testValues.find(v=>v.value && v.value?.trim() !== '')!.expected = false; // Adjust expected for non-empty strings

    for(const { value, expected } of testValues) {
        it(`should return ${expected} for ${value} when using isEmpty`, () => {
            const result = utils.isEmpty(value);
            expect(result).toBe(expected);
        });
    }
});