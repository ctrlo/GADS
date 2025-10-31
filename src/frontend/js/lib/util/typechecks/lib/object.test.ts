import { describe, it, expect } from "@jest/globals";
import { isObject, hasMethod } from "./object";

describe("Object Type Checks", () => {
    describe("isObject", () => {
        it("should return true for plain objects", () => {
            expect(isObject({})).toBe(true);
            expect(isObject({ key: "value" })).toBe(true);
        });

        it("should return false for non-object values", () => {
            expect(isObject(null)).toBe(false);
            expect(isObject(undefined)).toBe(false);
            expect(isObject(123)).toBe(false);
            expect(isObject("string")).toBe(false);
            expect(isObject([])).toBe(false);
        });

        it("should return true for instances of Object", () => {
            expect(isObject(new Object())).toBe(true);
        });
    });

    describe("hasMethod", () => {
        it("should return true if the object has the specified method", () => {
            const obj = { method: () => {} };
            expect(hasMethod(obj, "method")).toBe(true);
        });

        it("should return false if the object does not have the specified method", () => {
            const obj = { anotherMethod: () => {} };
            expect(hasMethod(obj, "method")).toBe(false);
        });

        it("should return false for non-object values", () => {
            expect(hasMethod(null, "method")).toBe(false);
            expect(hasMethod(undefined, "method")).toBe(false);
            expect(hasMethod(123, "method")).toBe(false);
            expect(hasMethod("string", "method")).toBe(false);
            expect(hasMethod([], "method")).toBe(false);
        });

        it("should return false if the method is not a function", () => {
            const obj = { method: "not a function" };
            expect(hasMethod(obj, "method")).toBe(false);
        });
    });
});
