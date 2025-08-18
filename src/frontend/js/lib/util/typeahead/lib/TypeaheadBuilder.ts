import { MapperFunction, map } from 'util/mapper/mapper';
import { TypeaheadSourceOptions } from './TypeaheadSourceOptions';
import { Typeahead } from './Typeahead';

type TypeaheadCallback = (suggestion: { name: string, id: number }) => void;

/**
 * TypeaheadBuilder class for building Typeahead class
 */
export class TypeaheadBuilder {
    private $input: JQuery<HTMLInputElement>;
    private callback: TypeaheadCallback;
    private name: string;
    private ajaxSource: string;
    private appendQuery: boolean;
    private data: any;
    private mapper: MapperFunction = (data: any) => {return data.map(d=> {return {name: d.name, id: d.id}})};
    private dataBuilder: Function;
    private method: 'GET' | 'POST' = 'GET';

    /**
     * Constructor for TypeaheadBuilder class
     */
    constructor() {
        this.appendQuery = false;
        this.data = undefined;
    }

    /**
     * Set the HTTP method to use for the ajax request
     * @param method - The HTTP method to use for the ajax request, defaults to 'GET'
     * @returns The builder being used
     */
    withMethod(method: 'GET'|'POST'='GET') {
        if(method !== 'GET' && method !== 'POST') {
            throw new Error("Method must be either 'GET' or 'POST'");
        }
        this.method = method;
        return this;
    }

    /**
     * Set the input element to attach typeahead to
     * @param {JQuery<HTMLElement>} $input The input element to attach typeahead to
     * @returns {this} The builder being used
     */
    withInput($input: JQuery<HTMLInputElement>): this {
        this.$input = $input;
        return this;
    }

    /**
     * Set the callback function to be called when a suggestion is selected
     * @param {TypeaheadCallback} callback The callback function to be called when a suggestion is selected - this function should take in a suggestion of type T and return void
     * @returns {this} The builder being used
     */
    withCallback(callback: TypeaheadCallback): this {
        this.callback = callback;
        return this;
    }

    /**
     * Set the name of the typeahead data source
     * @param {string} name The name of the typeahead data source
     * @returns {this} The builder being used
     */
    withName(name: string): this {
        this.name = name;
        return this;
    }

    /**
     * Set the URL to the typeahead ajax source
     * @param {string} ajaxSource The url to the ajax source
     * @returns {this} The builder being used
     */
    withAjaxSource(ajaxSource: string): this {
        this.ajaxSource = ajaxSource;
        return this;
    }

    /**
     * Sets the append query to true
     * @param {boolean} appendQuery Whether to append the query to the ajax request
     * @returns {this} The builder being used
     */
    withAppendQuery(appendQuery: boolean = true): this {
        this.appendQuery = appendQuery;
        return this;
    }

    /**
     * Sets the data to be sent with the ajax request
     * @param {*} data The data to be sent with the ajax request
     * @returns {this} The builder being used
     */
    withData(data: any): this {
        this.dataBuilder = undefined;
        this.data = data;
        return this;
    }

    /**
     * Sets the mapper to use with the typeahead
     * @param {MapperFunction} mapper The mapper function to be used to map the ajax response to the typeahead suggestion
     * @returns {this} The builder being used
     */
    withMapper(mapper: MapperFunction): this {
        this.mapper = mapper;
        return this;
    }

    /**
     * Sets to use the default mapper function
     * @returns {this} The builder being used
     */
    withDefaultMapper(): this {
        this.mapper = map;
        return this;
    }

    /**
     * Set the data builder function to be used to build the data to be sent with the ajax request
     * @param {(...args: any[])=>any} dataBuilderFunction The function to be used to build the data to be sent with the ajax request
     * @returns {this} The builder being used
     */
    withDataBuilder(dataBuilderFunction: (...args: any[]) => any): this {
        this.data = undefined;
        this.dataBuilder = dataBuilderFunction;
        return this;
    }

    /**
     * Build the Typeahead class
     * @returns {Typeahead} The built Typeahead class
     * @throws {Error} If input, callback, name, or ajax source is not set
     */
    build() {
        if (!this.$input) throw new Error("Input not set");
        if (!this.callback) throw new Error("Callback not set");
        if (!this.name) throw new Error("Name not set");
        if (!this.ajaxSource) throw new Error("Ajax source not set");
        const options = new TypeaheadSourceOptions(this.name, this.ajaxSource, this.mapper, this.appendQuery, this.data, this.dataBuilder, this.method);
        return new Typeahead(this.$input, this.callback, options);
    }
}
