import { map } from "./mapper";

describe('mapper', () => {
    it('should map from ScriptResponse to name/id pair', () => {
        const scriptResponse = {
            error: 0,
            records: [
                {
                    label: "test",
                    id: 1
                }
            ]
        };
        const expected = [
            {
                name: "test",
                id: 1
            }
        ];
        const actual = map(scriptResponse);
        expect(actual).toEqual(expected);
    });
});