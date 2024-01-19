import { map } from "./mapper";

describe('mapper', () => {
    it('should map from ScriptResponse to name/id pair', () => {
        const scriptResponse = {
            error: 0,
            records: [
                {
                    label: "test",
                    id: 1
                },
                {
                    label: "test2",
                    id: 2
                }
            ]
        };
        const expected = [
            {
                name: "test",
                id: 1
            },
            {
                name: "test2",
                id: 2
            }
        ];
        const actual = map(scriptResponse);
        expect(actual).toEqual(expected);
    });

    it('should map from a string to name/id pair', () => {
        const response = { error: 0, records: ["test", "test2"] };
        const expected = [
            {
                name: "test",
                id: 0
            },
            {
                name: "test2",
                id: 1
            }
        ];
        const actual = map(response);
        expect(actual).toEqual(expected);
    });

    it('should filter out duplicate values from the response', () => {
        const response = { error: 0, records: ["test", "test", "test"] };
        const expected = [
            {
                name: "test",
                id: 0
            }
        ];
        const actual = map(response);
        expect(actual).toEqual(expected);
    });

    it('should filter out duplicate values from the response when objects are returned', () => {
        const response = { error: 0, records: [{ label: "test", id: 1 }, { label: "test", id: 4 }, { label: "test", id: 752 }] };
        const expected = [
            {
                name: "test",
                id: 1
            }
        ];
        const actual = map(response);
        expect(actual).toEqual(expected);
    });
});
