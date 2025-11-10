import { describe, it, expect } from '@jest/globals';
import { isString, isEmptyString } from './string';

describe('String Type Checks', () => {
    describe('isString', () => {
        it('should return true for string inputs', () => {
            expect(isString('Hello')).toBe(true);
            expect(isString('')).toBe(true);
        });

        it('should return false for non-string inputs', () => {
            expect(isString(42)).toBe(false);
            expect(isString({})).toBe(false);
            expect(isString(null)).toBe(false);
            expect(isString(undefined)).toBe(false);
            expect(isString(true)).toBe(false);
        });
    });

    describe('isEmptyString', () => {
        it('should return true for empty string', () => {
            expect(isEmptyString('')).toBe(true);
        });

        it('should return false for non-empty strings', () => {
            expect(isEmptyString('Hello')).toBe(false);
        });

        it('should return false for non-string inputs', () => {
            expect(isEmptyString(42)).toBe(false);
            expect(isEmptyString({})).toBe(false);
            expect(isEmptyString(null)).toBe(false);
            expect(isEmptyString(undefined)).toBe(false);
            expect(isEmptyString(true)).toBe(false);
        });
    });
});