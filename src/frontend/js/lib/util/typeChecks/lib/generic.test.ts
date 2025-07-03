import { isDefined } from "./generic";

describe("Defined Checks", () => {
    it("Checks for isDefined", () => {
        expect(isDefined("test")).toBe(true);
        expect(isDefined(123)).toBe(true);
        expect(isDefined({})).toBe(true);
        expect(isDefined([])).toBe(true);
        expect(isDefined(true)).toBe(true);
        expect(isDefined(false)).toBe(true);
        expect(isDefined(null)).toBe(false);
        expect(isDefined(undefined)).toBe(false);
    });
});