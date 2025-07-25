/**
 * A component for handling typeahead functionality
 */
class AutocompleteComponent {
    readonly type = 'autocomplete';
    input: JQuery<HTMLInputElement>;
    el: JQuery<HTMLElement>;

    /**
     * Create an instance of AutocompleteComponent
     * @param {HTMLElement | JQuery<HTMLElement>} el The HTML element or jQuery object that contains the input field for autocomplete
     */
    constructor(el: HTMLElement | JQuery<HTMLElement>) {
        this.el = $(el);
        this.input = this.el.find<HTMLInputElement>('.form-control');
    }

    /**
     * Initializes the autocomplete functionality by setting up the typeahead
     */
    init() {
        const suggestionCallback = (suggestion: { id: number, name: string }) => {
            this.el.find('input[type="hidden"]').val(suggestion.id);
        };

        import(/* webpackChunkName: "typeahead" */ 'util/typeahead')
            .then(({ default: TypeaheadBuilder }) => {
                const builder = new TypeaheadBuilder();
                builder
                    .withInput(this.input)
                    .withCallback(suggestionCallback)
                    .withAjaxSource(this.getURL())
                    .withAppendQuery()
                    .withName('users')
                    .build();
            });
    }

    /**
     * Create the URL for the autocomplete API endpoint
     * @returns {string} The URL for the autocomplete API endpoint
     */
    getURL(): string {
        //@ts-expect-error "Testing code used by Digitpaint."
        const devEndpoint = window.siteConfig?.urls?.autocompleteApi;
        const layoutIdentifier = $('body').data('layout-identifier');

        return devEndpoint ?? `/${layoutIdentifier ? layoutIdentifier + '/' : ''}match/user/?q=`;
    }
}

/**
 * Creates an instance of AutocompleteComponent and initializes it
 * @param {HTMLElement | JQuery<HTMLElement>} el The HTML element or jQuery object that contains the input field for autocomplete
 */
export default function autocompleteComponent(el: HTMLElement | JQuery<HTMLElement>) {
    new AutocompleteComponent(el).init();
}
