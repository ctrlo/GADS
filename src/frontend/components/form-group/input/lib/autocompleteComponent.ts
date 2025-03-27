/**
 * Autocomplete component
 */
class AutocompleteComponent {
    readonly type = 'autocomplete';
    input: JQuery<HTMLInputElement>;
    el: JQuery<HTMLElement>;

    /**
     * Create a new autocomplete component
     * @param el The element to attach the autocomplete to
     */
    constructor(el: HTMLElement | JQuery<HTMLElement>) {
        this.el = $(el);
        this.input = this.el.find<HTMLInputElement>('.form-control');
    }

    /**
     * Initialize the autocomplete component
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
     * Get the url to use for the autocomplete
     * @returns The URL to use for the autocomplete
     */
    getURL(): string {
        //@ts-expect-error "Testing code used by Digitpaint."
        const devEndpoint = window.siteConfig?.urls?.autocompleteApi;
        const layoutIdentifier = $('body').data('layout-identifier');

        return devEndpoint ?? `/${layoutIdentifier ? layoutIdentifier + '/' : ''}match/user/?q=`;
    }
}

/**
 * Create a new autocomplete component
 * @param el The element to attach the autocomplete to
 */
export default function autocompleteComponent(el: HTMLElement | JQuery<HTMLElement>) {
    new AutocompleteComponent(el).init();
}
