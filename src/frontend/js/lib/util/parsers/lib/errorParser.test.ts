import { createErrorMessage } from "./errorParser";

describe("error parsing", () => {
    it("Checks for createErrorMessage", () => {
        expect(createErrorMessage('{"message": "An error occurred"}')).toBe("An error occurred");
        expect(createErrorMessage({ message: "An error occurred" })).toBe("An error occurred");
        expect(createErrorMessage({})).toBe("{}");
        expect(createErrorMessage("not a json")).toBe("not a json");
        expect(() => createErrorMessage(123)).toThrow("Invalid input type");
        expect(() => createErrorMessage(null)).toThrow("Invalid input type");
        expect(() => createErrorMessage(undefined)).toThrow("Invalid input type");
    });
});
