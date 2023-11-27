import { ScriptResponse } from "./interfaces"

/**
 * Map the script response to a response that the typeahead can use
 * @param r The response from the script
 * @returns The mapped response
 */
export const map: (ScriptResponse) => { name: string, id: number }[] = (r) => {
    return r.records.map((record) => {
        return {
            name: record.label,
            id: record.id
        }
    });
}