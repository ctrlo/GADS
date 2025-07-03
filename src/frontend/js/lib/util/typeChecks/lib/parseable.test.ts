import { isJsonParseable } from "./parseable";

describe("isJsonParseable", () => {
    it("Checks for isJsonParseable", () => {
        expect(isJsonParseable('{"key": "value"}')).toBe(true);
        expect(isJsonParseable('{"key": "value"')).toBe(false);
        expect(isJsonParseable("not a json")).toBe(false);
        expect(isJsonParseable(123)).toBe(false);
        expect(isJsonParseable(null)).toBe(false);
        expect(isJsonParseable(undefined)).toBe(false);
    });
});