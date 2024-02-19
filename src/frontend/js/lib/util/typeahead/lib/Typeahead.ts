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
        this.$input.typeahead({
            hint: true,
            highlight: true,
            minLength: 1
        }, {
            name: name,
            source: (query, syncResults, asyncResults) => {
                this.debounce(() => {
                    const request: JQuery.AjaxSettings<any> = {
                        url: ajaxSource + (appendQuery ?  query : ""),
                        dataType: "json",
                        beforeSend: () => {
                            this.ajaxRequest && this.ajaxRequest.abort();
                        },
                        success: (data) => {
                            if (window.test) console.log("Typeahead data:", data);
                            const mapped = mapper(data);
                            if (window.test) console.log("Typeahead mapped data:", mapped);
                            const filtered = this.filterData(mapped, query);
                            if (window.test) console.log("Typeahead filtered data:", filtered);
                            asyncResults(filtered);
                        },
                        async: window.test ? false : true,
                        cache: false
                    };
                    if (this.sourceOptions.data) request.data = this.sourceOptions.data;
                    if (this.sourceOptions.dataBuilder) request.data = this.sourceOptions.dataBuilder();
                    if (window.test) console.log("Typeahead request: ", request);
                    this.ajaxRequest = $.ajax(request);
                }, 200);
            },
            display: 'name',
            limit: 10,
            templates: {
                suggestion: (item: { name: String, id: number }) => {
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

    /**
     * Debounce function to prevent multiple requests being sent to the server - not required when testing, as we want to trigger immediately!
     * @param func The function to debounce
     * @param wait The time to wait before calling the function
     */
    debounce(func: Function, wait: number) {
        if (window.test) {
            console.log("Test mode - no debounce applied!")
            return func();
        }
        if(this.timeout) clearTimeout(this.timeout);
        // Weird casting error - having to cast to this in order to stop typing error.
        this.timeout = setTimeout(<(args:void)=>void>func, wait);
    }
};
