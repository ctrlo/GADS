/**
 * ScriptResponse interface for Typeahead class script responses
 * @param error - error code (if there is one)
 * @param records - records returned from the script
 */
export interface ScriptResponse {
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
 * TypeaheadSourceOptions interface for Typeahead class
 * @param name - name of the typeahead data source
 * @param ajaxSource - url to the ajax source
 * @param appendQuery - whether to append the query to the ajax source url
 * @param data - data to be sent with the ajax request (if any)
 */
export interface TypeaheadSourceOptions {
    name: string,
    ajaxSource: string;
    appendQuery?: boolean;
    data?: any;
}