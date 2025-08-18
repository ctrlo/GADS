import { MapperFunction } from 'util/mapper/mapper';

/**
 * TypeaheadSourceOptions class for configuring typeahead data sources
 */
export class TypeaheadSourceOptions {
    /**
     * Create a new TypeaheadSourceOptions instance
     * @param {string} name The name of the typeahead source
     * @param {string} ajaxSource The URL for the AJAX source
     * @param {MapperFunction} mapper The function to map the data
     * @param {boolean} appendQuery Whether to append the query to the AJAX request
     * @param {*} data Any additional data to send with the request
     * @param {(...args:any[]) => any} dataBuilder A function to build the data for the request
     */
    constructor(
        public name: string,
        public ajaxSource: string,
        public mapper: MapperFunction,
        public appendQuery: boolean,
        public data: any,
        public dataBuilder: Function,
        public method: 'GET' | 'POST' = 'GET') {
    }
}
