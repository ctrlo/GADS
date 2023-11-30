/**
 * TypeaheadSourceOptions interface for Typeahead class
 * @param name - name of the typeahead data source
 * @param ajaxSource - url to the ajax source
 * @param appendQuery - whether to append the query to the ajax source url
 * @param data - data to be sent with the ajax request (if any)
 */

import { MapperFunction } from "util/mapper/mapper"

export interface TypeaheadSourceOptions {
    isStatic: boolean;
    name: string;
    data?: any;
}

export class TypeaheadAjaxSourceOptions implements TypeaheadSourceOptions {
    constructor(
        public name: string,
        public ajaxSource: string,
        public mapper: MapperFunction = (d) => { return d.map(data => { return { id: data.id, name: data.name } }) },
        public appendQuery: boolean = false,
        public data: any = undefined) {
    }

    readonly isStatic: boolean=true;
}

export class TypeaheadStaticSourceOptions implements TypeaheadSourceOptions {
    constructor(
        public name: string,
        public data: any) {
    }

    readonly isStatic: boolean=true;
}