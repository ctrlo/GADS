import { describe, it, expect } from "@jest/globals";
import { isDefined } from "./generic";

describe("Defined Checks", () => {
    it("should return true for defined values", () => {
        expect(isDefined(0)).toBe(true);
        expect(isDefined("")).toBe(true);
        expect(isDefined(false)).toBe(true);
        expect(isDefined({})).toBe(true);
        expect(isDefined([])).toBe(true);
    });
    
    it("should return false for undefined or null values", () => {
        expect(isDefined(undefined)).toBe(false);
        expect(isDefined(null)).toBe(false);
    });
});
