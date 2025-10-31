import { describe, it, expect } from "@jest/globals";
import { isNumber } from "./number";

describe("isNumber", () => {
    it("should return true for numbers", () => {
        expect(isNumber(123)).toBe(true);
        expect(isNumber(0)).toBe(true);
        expect(isNumber(-456)).toBe(true);
        expect(isNumber(3.14)).toBe(true);
    });

    it("should return false for non-number values", () => {
        expect(isNumber(null)).toBe(false);
        expect(isNumber(undefined)).toBe(false);
        expect(isNumber("string")).toBe(false);
        expect(isNumber({})).toBe(false);
        expect(isNumber([])).toBe(false);
        expect(isNumber(new Map())).toBe(false);
    });

    it("should return true for Number objects", () => {
        expect(isNumber(new Number(123))).toBe(true);
    });
});
