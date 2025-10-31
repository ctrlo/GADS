import { describe, it, expect } from "@jest/globals";
import { isArray } from "./array";

describe("isArray", () => {
    it("should return true for arrays", () => {
        expect(isArray([])).toBe(true);
        expect(isArray([1, 2, 3])).toBe(true);
        expect(isArray(["a", "b", "c"])).toBe(true);
    });

    it("should return false for non-array values", () => {
        expect(isArray(null)).toBe(false);
        expect(isArray(undefined)).toBe(false);
        expect(isArray(123)).toBe(false);
        expect(isArray("string")).toBe(false);
        expect(isArray({})).toBe(false);
        expect(isArray(new Map())).toBe(false);
    });
});