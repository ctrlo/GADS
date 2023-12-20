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
                id: 0
            }
        ];
        const actual = map(response);
        expect(actual).toEqual(expected);
    });
});