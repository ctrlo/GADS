class AutocompleteComponent {
    readonly type = 'autocomplete';
    input: JQuery<HTMLInputElement>;
    el: JQuery<HTMLElement>;

    constructor(el: HTMLElement | JQuery<HTMLElement>) {
        this.el = $(el);
        this.input = this.el.find<HTMLInputElement>('.form-control');
    }

    init() {
        const suggestionCallback = (suggestion: { id: number, name:string }) => {
            this.el.find('input[type="hidden"]').val(suggestion.id);
        };

        import('util/typeahead')
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

    getURL(): string {
        const devEndpoint = window.siteConfig?.urls?.autocompleteApi;
        const layoutIdentifier = $('body').data('layout-identifier');

        return devEndpoint ?? `/${layoutIdentifier ? layoutIdentifier + '/' : ''}match/user/?q=`;
    }
}

export default function autocompleteComponent(el: HTMLElement | JQuery<HTMLElement>) {
    new AutocompleteComponent(el).init();
}
