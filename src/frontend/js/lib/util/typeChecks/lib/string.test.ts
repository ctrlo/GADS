import {describe, it, expect} from "@jest/globals";
import * as stringChecks from "./string";

describe("String checks", () => {
    it("isString", () => {
        expect(stringChecks.isString("test")).toBe(true);
        expect(stringChecks.isString(123)).toBe(false);
        expect(stringChecks.isString({})).toBe(false);
        expect(stringChecks.isString([])).toBe(false);
        expect(stringChecks.isString(null)).toBe(false);
        expect(stringChecks.isString(undefined)).toBe(false);
    });
    
    it("isEmptyString", () => {
        expect(stringChecks.isEmptyString("")).toBe(true);
        expect(stringChecks.isEmptyString("test")).toBe(false);
        expect(stringChecks.isEmptyString(123)).toBe(false);
        expect(stringChecks.isEmptyString({})).toBe(false);
        expect(stringChecks.isEmptyString([])).toBe(false);
        expect(stringChecks.isEmptyString(null)).toBe(false);
        expect(stringChecks.isEmptyString(undefined)).toBe(false);
    });
});
