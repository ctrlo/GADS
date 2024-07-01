import { MapperFunction } from "util/mapper/mapper";


/**
 * TypeaheadSourceOptions class for creating a typeahead data source
 * @param name - name of the data source
 * @param ajaxSource - URL to the ajax source
 * @param mapper - mapper function to be used to map the ajax response to the typeahead suggestion
 * @param appendQuery - whether to append the query to the ajax source
 * @param data - data to be sent with the ajax request
 * @param dataBuilder - function to build the data to be sent with the ajax request
 */
export class TypeaheadSourceOptions {
    constructor(
        public name: string,
        public ajaxSource: string,
        public mapper: MapperFunction,
        public appendQuery: boolean,
        public data: any,
        public dataBuilder: Function) {
    }
}