import { hasProperty } from "./properties";

it("Checks for hasProperty", () => {
    const obj = { key: "value" };
    expect(hasProperty(obj, "key")).toBe(true);
    expect(hasProperty(obj, "nonExistentKey")).toBe(false);
    expect(hasProperty({}, "key")).toBe(false);
    // Edge cases
    // @ts-ignore
    expect(hasProperty(null, "key")).toBe(false);
    // @ts-ignore
    expect(hasProperty(undefined, "key")).toBe(false);
    // @ts-ignore
    expect(hasProperty("string", "length")).toBe(false);
});