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
        const { data, appendQuery, mapper, name, ajaxSource, method } = this.sourceOptions;
        const bloodhound = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.whitespace,
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            remote: {
                url: ajaxSource + (appendQuery ? "%QUERY" : ""),
                wildcard: '%QUERY',
                transform: (response) => {
                    return mapper(response);
                },
                rateLimitBy: 'debounce',
                rateLimitWait: 300,
                cache: false,
                // Using composite typing here because the first three properties are required by typeahead.js, whereas the rest are specific to this implementation
                transport: (request: { url: string, type: string, dataType: string } & { data?: any }, success: (resp: any) => void, error: (err: any) => void) => {
                    request.type = method;
                    request.data = data ? data : this.sourceOptions.dataBuilder ? this.sourceOptions.dataBuilder() : undefined;
                    $.ajax(request)
                        .done((data)=>{
                            console.log("Typeahead ajax request successful:", data);
                            success(data);
                        })
                        .fail((jqXHR, textStatus, errorThrown) => {
                            console.error("Typeahead ajax request failed:", textStatus, errorThrown, jqXHR.responseText);
                            error(errorThrown);
                        }
                        );
                }
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
            limit: 20,
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

        if (window.test) {
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
}
