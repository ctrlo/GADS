import { MapperFunction } from "util/mapper/mapper";
import { TypeaheadSourceOptions } from "./TypeaheadSourceOptions";
import { Typeahead } from "./Typeahead";

type TypeaheadCallback = (suggestion: {name:string, id:number}) => void;

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
export class TypeaheadBuilder {
    private $input: JQuery<HTMLInputElement>;
    private callback: TypeaheadCallback;
    private name: string;
    private ajaxSource: string;
    private appendQuery: boolean;
    private data: any;
    private mapper: MapperFunction = (data: any) => {return data.map(d=> {return {name: d.name, id: d.id}})};
    private dataBuilder: Function;

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
    withCallback(callback: TypeaheadCallback) {
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
        this.dataBuilder = undefined;
        this.data = data;
        return this;
    }

    /**
     * Sets the mapper to use with the typeahead
     * @param mapper The mapper function to be used to map the ajax response to the typeahead suggestion
     * @returns The builder being used
     */
    withMapper(mapper: MapperFunction) {
        this.mapper = mapper;
        return this;
    }

    /**
     * Set the data builder function to be used to build the data to be sent with the ajax request
     * @param dataBuilderFunction The function to be used to build the data to be sent with the ajax request
     * @returns The builder being used
     */
    withDataBuilder(dataBuilderFunction:Function) {
        this.data = undefined;
        this.dataBuilder = dataBuilderFunction;
        return this;
    }

    /**
     * Build the Typeahead class
     * @returns The built Typeahead class
     */
    build() {
        if (!this.$input) throw new Error("Input not set");
        if (!this.callback) throw new Error("Callback not set");
        if (!this.name) throw new Error("Name not set");
        if (!this.ajaxSource) throw new Error("Ajax source not set");
        const options = new TypeaheadSourceOptions(this.name, this.ajaxSource, this.mapper, this.appendQuery, this.data, this.dataBuilder);
        return new Typeahead(this.$input, this.callback, options);
    }
}