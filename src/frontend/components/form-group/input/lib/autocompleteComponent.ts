import InputBase from './inputBase';

class AutocompleteComponent extends InputBase {
  readonly type = 'autocomplete';
  
  init() {
    const suggestionCallback = (suggestion: { id: number, name: string }) => {
      this.el.find('input[type="hidden"]').val(suggestion.id);
    };

    import(/* webpackChunkName: "typeahead" */ 'util/typeahead')
      .then(({default: TypeaheadBuilder}) => {
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
    //@ts-expect-error "Testing code used by Digitpaint."
    const devEndpoint = window.siteConfig?.urls?.autocompleteApi;
    const layoutIdentifier = $('body').data('layout-identifier');

    return devEndpoint ?? `/${layoutIdentifier ? layoutIdentifier + '/' : ''}match/user/?q=`;
  }
}

const autocompleteComponent = (el: HTMLElement | JQuery<HTMLElement>) => {
  const component = new AutocompleteComponent(el);
  component.init();
  return component;
}

export default autocompleteComponent;