import "typeahead.js";
import Bloodhound from "typeahead.js/dist/bloodhound";
import { TypeaheadSourceOptions } from "./TypeaheadSourceOptions";
import { MappedResponse } from "util/mapper/mapper";

/**
 * Typeahead class for creating a typeahead
 * @param $input - input element to attach typeahead to
 * @param callback - callback function to be called when a suggestion is selected
 * @param sourceOptions - options for the typeahead data source
 */
export class Typeahead {
    private timeout = null;
    private ajaxRequest: JQuery.jqXHR<any>;

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
    private init() {
        const { appendQuery, mapper, name, ajaxSource } = this.sourceOptions;
        const bloodhound = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.whitespace,
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            remote: {
                url: ajaxSource + (appendQuery ?  "%QUERY" : ""),
                wildcard: '%QUERY',
                transform: (response) => {
                    return mapper(response);
                },
            }
        });
        this.$input.typeahead({
            hint: false,
            highlight: false,
            minLength: 1
        }, {
            name: name,
            source: bloodhound,
            display: 'name',
            limit: 10,
            templates: {
                suggestion: (item: MappedResponse) => {
                    return `<div>${item.name}</div>`;
                },
                pending: () => {
                    return `<div>Loading...</div>`;
                },
                notFound: () => {
                    return `<div>No results found</div>`;
                }
            },
        });

        this.$input.on('typeahead:select', (ev: any, suggestion: MappedResponse) => {
            this.callback(suggestion);
        });

        if(window.test) {
            this.$input.on("typeahead:asyncrequest", () => {
                console.log("Typeahead async request");
            });

            this.$input.on("typeahead:asyncreceive", () => {
                console.log("Typeahead async receive");
            });

            this.$input.on("typeahead:asynccancel", () => {
                console.log("Typeahead async cancel");
            });
        }
    }

    /**
     * This function is to filter the data based on the query
     * @param query The query to use in this filter
     * @param data The data to filter
     * @returns The filtered data
     */
    filterData(data: MappedResponse[], query?: string): MappedResponse[] {
        // I know that this was originally above, and _shouldn't_ need to be here, but there is a bug in the filtering somewhere,
        // and I need to unit test it here to ensure this isn't the problem! - DR 19/02/2024
        if(!query || !query.length) {
            if(window.test) console.log("No query, returning data:", data);
            return data;
        }
        if(window.test) console.log("Filtering data with query:", query);
        return data.filter((item) => {
            return item.name.toLowerCase().includes(query.toLowerCase());
        });
    }
};
