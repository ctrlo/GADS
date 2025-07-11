/**
 * Mapped response interface for Typeahead class
 */
export type MappedResponse = { name: string, id: number };

/**
 * Mapper function type for Typeahead class to map responses
 */
export type MapperFunction = (any: any) => MappedResponse[];

/**
 * ScriptResponse interface for Typeahead class script responses
 * @prop error - error code (if there is one)
 * @prop records - records returned from the script
 */
interface ScriptResponse {
    error: number;
    records: Record[];
}

/**
 * TypeaheadResponse interface for Typeahead class responses
 * @prop name - name of the suggestion
 * @prop id - id of the suggestion
 */
interface Record {
    label: string;
    id: number;
}

/**
 * Map the script response to a response that the typeahead can use
 * @param r The response from the script
 * @returns The mapped response
 */
export const map: MapperFunction = (r: ScriptResponse) => {
    const result = [];
    let i = 0;
    r.records.forEach((record) => {
        if (record instanceof Object) {
            result.push({
                name: record.label,
                id: record.id
            });
        } else {
            result.push({
                name: record,
                id: i++
            });
        }
    })
    return result;
}
