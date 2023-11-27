import { MappedResponse } from "./interfaces";

/**
 * TypeaheadSourceOptions interface for Typeahead class
 * @param name - name of the typeahead data source
 * @param ajaxSource - url to the ajax source
 * @param appendQuery - whether to append the query to the ajax source url
 * @param data - data to be sent with the ajax request (if any)
 */

export class TypeaheadSourceOptions {
    constructor(
        public name: string,
        public ajaxSource: string,
        public mapper: (data: any) => MappedResponse[] = (d) => { return d.map(data => { return { id: data.id, name: data.name } }) },
        public appendQuery: boolean = false,
        public data: any = undefined) {
    }
}
