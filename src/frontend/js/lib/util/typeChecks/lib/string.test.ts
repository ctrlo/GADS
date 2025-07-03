import { isString } from './string';

describe('isString', () => {
    it("Checks for isString", () => {
        expect(isString("test")).toBe(true);
        expect(isString(123)).toBe(false);
        expect(isString({})).toBe(false);
        expect(isString([])).toBe(false);
        expect(isString(true)).toBe(false);
        expect(isString(false)).toBe(false);
        expect(isString(null)).toBe(false);
        expect(isString(undefined)).toBe(false);
    });
});