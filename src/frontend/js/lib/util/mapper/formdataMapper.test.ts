import { formdataMapper } from './formdataMapper';

describe("Basic formdata mapper tests", () => {
    it("should map a simple object", () => {
        const data = {
            name: "John Doe",
            age: 30,
            email: "john@example.com"
        };
        const formData = new FormData();
        formData.append("name", "John Doe");
        formData.append("age", "30");
        formData.append("email", "john@example.com");
        expect(formdataMapper(data)).toEqual(formData);
    });

    it("should throw an error for nested objects deeper than one layer", () => {
        const data = {
            name: "John Doe",
            age: 30,
            email: "john@example.com",
            address: {
                street: "1234 Elm St",
                city: "Springfield",
                state: "IL",
                zip: {
                    code: 62701
                }
            }
        };
        expect(() => formdataMapper(data)).toThrow(new Error("Nested objects deeper than one layer are not supported"));
    });

    it('should return the same FormData object if it is passed in', () => {
        const formData = new FormData();
        formData.append("name", "John Doe");
        formData.append("age", "30");
        formData.append("email", "john@example.com");
        expect(formdataMapper(formData)).toBe(formData);
    });

    it('should throw an error if an empty object is passed in', () => {
        expect(() => formdataMapper({})).toThrow(new Error("Cannot map an empty object"));
    });

    it('should throw an error if an empty FormData object is passed in', () => {
        const formData = new FormData();
        expect(() => formdataMapper(formData)).toThrow(new Error("Cannot map an empty object"));
    });
});