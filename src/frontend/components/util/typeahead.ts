import "typeahead.js";

interface TypeaheadSourceOptions {
    name: string,
    ajaxSource: string;
    appendQuery?: boolean;
    data?: any;
}

class TypeaheadBuilder<T extends { name: string, id: number }> {
    private $input: JQuery<HTMLInputElement>;
    private callback: (suggestion: T) => void;
    private name: string;
    private ajaxSource: string;
    private appendQuery: boolean;
    private data: any;

    constructor() {
        this.appendQuery = false;
        this.data = undefined;
    }

    withInput($input: JQuery<HTMLInputElement>) {
        this.$input = $input;
        return this;
    }

    withCallback(callback: (suggestion: T) => void) {
        this.callback = callback;
        return this;
    }

    withName(name: string) {
        this.name = name;
        return this;
    }

    withAjaxSource(ajaxSource: string) {
        this.ajaxSource = ajaxSource;
        return this;
    }

    withAppendQuery() {
        this.appendQuery = true;
        return this;
    }

    withData(data: any) {
        this.data = data;
        return this;
    }

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

class Typeahead<T extends { name: string, id: number }> {
    constructor(private $input: JQuery<HTMLInputElement>, private callback: (suggestion: T) => void, private sourceOptions: TypeaheadSourceOptions) {
        this.init();
    }

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

export { TypeaheadBuilder };
