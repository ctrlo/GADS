import { isObject } from './object';

describe('isObject', () => {
    it("Checks for isObject", () => {
        expect(isObject({})).toBe(true);
        expect(isObject({ key: "value" })).toBe(true);
        expect(isObject([])).toBe(false);
        expect(isObject("")).toBe(false);
        expect(isObject(123)).toBe(false);
        expect(isObject(null)).toBe(false);
        expect(isObject(undefined)).toBe(false);
        expect(isObject(true)).toBe(false);
        expect(isObject(false)).toBe(false);
    });
})