import "typeahead.js";
import { MappedResponse } from "util/mapper/mapper";
import { TypeaheadSourceOptions } from "./TypeaheadSourceOptions";

/**
 * Typeahead class for creating a typeahead
 * @param $input - input element to attach typeahead to
 * @param callback - callback function to be called when a suggestion is selected
 * @param sourceOptions - options for the typeahead data source
 */
export class Typeahead {
    /**
     * Create a new Typeahead class
     * @param $input The input element to attach typeahead to
     * @param callback The callback function to be called when a suggestion is selected - this function should take in a suggestion of type T and return void
     * @param sourceOptions The options for the typeahead data source
     */
    constructor(private $input: JQuery<HTMLInputElement>, private callback: (suggestion: MappedResponse) => void, private sourceOptions: TypeaheadSourceOptions) {
        this.init();
    }

    /**
     * Initialize the typeahead
     */
    init() {
        const { appendQuery, mapper, name, ajaxSource } = this.sourceOptions;
        this.$input.typeahead({
            hint: true,
            highlight: true,
            minLength: 1
        }, {
            name: name,
            source: (query, syncResults, asyncResults) => {
                $.ajax({
                    url: ajaxSource + (appendQuery ? query : ""),
                    dataType: "json",
                    success: (data) => {
                        asyncResults(mapper(data).filter((item: MappedResponse) => { return item.name.toLowerCase().indexOf(query.toLowerCase()) !== -1; }));
                    }
                });
            },
            display: 'name',
            limit: 10,
            templates: {
                suggestion: (item: {name:String, id:number}) => {
                    return `<div>${item.name}</div>`;
                },
                pending: () => {
                    return `<div>Loading...</div>`;
                }
            }
        });

        this.$input.on('typeahead:select', (ev: any, suggestion: MappedResponse) => {
            this.callback(suggestion);
        });
    }
};