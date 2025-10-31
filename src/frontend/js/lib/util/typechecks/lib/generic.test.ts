import { describe, it, expect } from '@jest/globals';
import { isDefined } from './generic';

describe('isDefined', () => {
    it('should return true for defined inputs', () => {
        expect(isDefined<number>(42)).toBe(true);
        expect(isDefined<string>('Hello')).toBe(true);
        expect(isDefined<object>({})).toBe(true);
        expect(isDefined<boolean>(true)).toBe(true);
    });

    it('should return false for undefined or null inputs', () => {
        expect(isDefined(undefined)).toBe(false);
        expect(isDefined(null)).toBe(false);
    });
});
