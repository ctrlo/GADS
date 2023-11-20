import "typeahead.js";

/**
 * TypeaheadSourceOptions interface for Typeahead class
 * @param name - name of the typeahead data source
 * @param ajaxSource - url to the ajax source
 * @param appendQuery - whether to append the query to the ajax source url
 * @param data - data to be sent with the ajax request (if any)
 */
interface TypeaheadSourceOptions {
    name: string,
    ajaxSource: string;
    appendQuery?: boolean;
    data?: any;
}

/**
 * TypeaheadBuilder class for building Typeahead class
 * @type T - type of the suggestion extending `{ name: string, id: number }`
 * @param $input - input element to attach typeahead to
 * @param callback - callback function to be called when a suggestion is selected
 * @param name - name of the typeahead data source
 * @param ajaxSource - url to the ajax source
 * @param appendQuery - whether to append the query to the ajax source url
 * @param data - data to be sent with the ajax request (if any)
 * @returns Typeahead class
 * @throws Error if $input, callback, name, or ajaxSource is not set
 */
class TypeaheadBuilder<T extends { name: string, id: number }> {
    private $input: JQuery<HTMLInputElement>;
    private callback: (suggestion: T) => void;
    private name: string;
    private ajaxSource: string;
    private appendQuery: boolean;
    private data: any;

    /**
     * Constructor for TypeaheadBuilder class
     */
    constructor() {
        this.appendQuery = false;
        this.data = undefined;
    }

    /**
     * Set the input element to attach typeahead to
     * @param $input The input element to attach typeahead to
     * @returns The builder being used
     */
    withInput($input: JQuery<HTMLInputElement>) {
        this.$input = $input;
        return this;
    }

    /**
     * Set the callback function to be called when a suggestion is selected
     * @param callback The callback function to be called when a suggestion is selected - this function should take in a suggestion of type T and return void
     * @returns The builder being used
     */
    withCallback(callback: (suggestion: T) => void) {
        this.callback = callback;
        return this;
    }

    /**
     * Set the name of the typeahead data source
     * @param name The name of the typeahead data source
     * @returns The builder being used
     */
    withName(name: string) {
        this.name = name;
        return this;
    }

    /**
     * Set the URL to the typeahead ajax source
     * @param ajaxSource The url to the ajax source
     * @returns The builder being used
     */
    withAjaxSource(ajaxSource: string) {
        this.ajaxSource = ajaxSource;
        return this;
    }

    /**
     * Sets the append query to true
     * @returns The builder being used
     */
    withAppendQuery() {
        this.appendQuery = true;
        return this;
    }

    /**
     * Sets the data to be sent with the ajax request
     * @param data The data to be sent with the ajax request
     * @returns The builder being used
     */
    withData(data: any) {
        this.data = data;
        return this;
    }

    /**
     * Build the Typeahead class
     * @returns The built Typeahead class
     */
    build() {
        if(!this.$input) throw new Error("Input not set");
        if(!this.callback) throw new Error("Callback not set");
        if(!this.name) throw new Error("Name not set");
        if(!this.ajaxSource) throw new Error("Ajax source not set");
        return new Typeahead<T>(this.$input, this.callback, {
            name: this.name,
            ajaxSource: this.ajaxSource,
            appendQuery: this.appendQuery,
            data: this.data
        });
    }
}

/**
 * Typeahead class for creating a typeahead
 * @type T - type of the suggestion extending `{ name: string, id: number }`
 * @param $input - input element to attach typeahead to
 * @param callback - callback function to be called when a suggestion is selected
 * @param sourceOptions - options for the typeahead data source
 */
class Typeahead<T extends { name: string, id: number }> {
    /**
     * Create a new Typeahead class
     * @param $input The input element to attach typeahead to
     * @param callback The callback function to be called when a suggestion is selected - this function should take in a suggestion of type T and return void
     * @param sourceOptions The options for the typeahead data source
     */
    constructor(private $input: JQuery<HTMLInputElement>, private callback: (suggestion: T) => void, private sourceOptions: TypeaheadSourceOptions) {
        this.init();
    }

    /**
     * Initialize the typeahead
     */
    init() {
        this.$input.typeahead({
            hint: true,
            highlight: true,
            minLength: 1
        }, {
            name: this.sourceOptions.name,
            source: (query, syncResults, asyncResults) => {
                const appendQuery = this.sourceOptions.appendQuery;
                $.ajax({
                    url: this.sourceOptions.ajaxSource + (appendQuery ? query : ""),
                    dataType: "json",
                    success: (data) => {
                        if (appendQuery) {
                            asyncResults(data)
                        } else {
                            asyncResults(data.filter((item: T) => item.name.toLowerCase().includes(query.toLowerCase())));
                        };
                    }
                })
            },
            display: 'name',
            limit: 10,
            templates: {
                suggestion: (item: T) => {
                    return `<div>${item.name}</div>`;
                },
                pending: () => {
                    return `<div>Loading...</div>`;
                }
            }
        });

        this.$input.on('typeahead:select', (ev: any, suggestion: T) => { this.callback(suggestion); });
    }
};

/**
 * export the TypeaheadBuilder class for building Typeahead class - the rest of the class can remain encapsulated
 */
export { TypeaheadBuilder };
