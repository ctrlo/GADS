import "typeahead.js";
import { TypeaheadAjaxSourceOptions, TypeaheadSourceOptions, TypeaheadStaticSourceOptions } from "./TypeaheadSourceOptions";
import { MappedResponse } from "./mapper";

/**
 * Typeahead class for creating a typeahead
 * @param $input - input element to attach typeahead to
 * @param callback - callback function to be called when a suggestion is selected
 * @param sourceOptions - options for the typeahead data source
 */
export class Typeahead {
    public isStatic: boolean;

    /**
     * Create a new Typeahead class
     * @param $input The input element to attach typeahead to
     * @param callback The callback function to be called when a suggestion is selected - this function should take in a suggestion of type T and return void
     * @param sourceOptions The options for the typeahead data source
     */
    constructor(private $input: JQuery<HTMLInputElement>, private callback: (suggestion: MappedResponse) => void, private sourceOptions: TypeaheadSourceOptions) {
        if (sourceOptions.isStatic) {
            this.initStatic();
        } else {
            this.initAjax();
        }
    }

    /**
     * Initialize the typeahead
     */
    initStatic() {
        this.isStatic = true;
        const { data, name } = this.sourceOptions as TypeaheadStaticSourceOptions;
        this.$input.typeahead({
            hint: true,
            highlight: true,
            minLength: 1
        }, {
            name: name,
            source: (query, syncResults) => {
                syncResults(data.filter((item: MappedResponse) => { return item.name.toLowerCase().indexOf(query.toLowerCase()) !== -1; }));
            },
            display: 'name',
            limit: 10,
            templates: {
                suggestion: (item: { name: String, id: number }) => {
                    return `<div>${item.name}</div>`;
                }
            }
        });

        this.$input.on('typeahead:select', (ev: any, suggestion: MappedResponse) => {
            this.callback(suggestion);
        });
    }

    /**
     * Initialize the typeahead
     */
    initAjax() {
        this.isStatic = false;
        const { appendQuery, mapper, name, ajaxSource } = this.sourceOptions as TypeaheadAjaxSourceOptions;
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
                suggestion: (item: { name: String, id: number }) => {
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

