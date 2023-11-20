import "typeahead.js";

interface TypeaheadSourceOptions {
    name: string,
    ajaxSource: string;
    appendQuery: boolean;
}

class Typeahead<T extends { name: string, id: number }> {
    constructor(private $input: JQuery<HTMLInputElement>, private callback: (suggestion: T) => void, private sourceOptions: TypeaheadSourceOptions) {
        this.init();
    }

    init() {
        this.$input.typeahead(null, {
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

export { Typeahead, TypeaheadSourceOptions };
