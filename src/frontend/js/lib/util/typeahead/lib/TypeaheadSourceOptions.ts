/**
 * TypeaheadSourceOptions interface for Typeahead class
 * @param name - name of the typeahead data source
 * @param ajaxSource - url to the ajax source
 * @param appendQuery - whether to append the query to the ajax source url
 * @param data - data to be sent with the ajax request (if any)
 */

import {MapperFunction} from "util/mapper/mapper"

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