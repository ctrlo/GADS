export type MappedResponse = { name: string, id: number };
export type MapperFunction = (any) => MappedResponse[];

/**
 * ScriptResponse interface for Typeahead class script responses
 * @param error - error code (if there is one)
 * @param records - records returned from the script
 */
interface ScriptResponse {
    error: number;
    records: Record[];
}

/**
 * TypeaheadResponse interface for Typeahead class responses
 * @param name - name of the suggestion
 * @param id - id of the suggestion
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
export const map: MapperFunction = (r:ScriptResponse) => {
    return r.records.map((record) => {
        return {
            name: record.label,
            id: record.id
        }
    });
}