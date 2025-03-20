import { Component } from "component";

export default class ListboxComponent extends Component {
  items: { text: string, order: number, controls: JQuery<HTMLElement> }[] = [];
  $el: JQuery<HTMLElement>;

  constructor(element: HTMLElement) {
    super(element);
    this.$el = $(element);
    if (!this.$el || this.$el.length === 0) {
      throw new Error('No element provided');
    }
  }

  addItem(text: string, order: number, controls: HTMLElement | JQuery<HTMLElement> | string) {
    const $item = this.coerce(controls);
    this.items = this.items.filter((item) => item.order !== order);
    this.items = [...this.items, { text, order, controls: $item }].sort((a, b) => a.order - b.order);
    this.render();
  }

  private render() {
    const $target = this.$el.find('.listbox-content');
    if (!$target || $target.length === 0) {
      throw new Error('No element provided');
    }
    $target.empty();
    this.items.forEach(({ text, order, controls }) => {
      const item = document.createElement('div');
      const $item = $(item);
      $item.attr("tabindex", "0");
      $item.attr('data-order', order);
      $item.text(text);
      $item.addClass('listbox-item');
      $item.on('click', () => {
        this.onClick(this.coerce(controls));
      });
      $item.on('keydown', (ev) => {
        if (ev.key == ' ' || ev.key == 'Enter') $(ev.target).trigger('click')
        if (ev.key == 'ArrowUp') {
          const index = $(ev.target).data('order') - 1;
          if (index >= 0) $(`.listbox-item[data-order=${index}]`).trigger('focus');
        }
        if (ev.key == 'ArrowDown') {
          const index = $(ev.target).data('order') + 1;
          if (index < this.items.length) $(`.listbox-item[data-order=${index}]`).trigger('focus');
        }
      })
      $target.append($item)
    });
  }

  removeItem(text: string) {
    const item = this.$el.find(`.listbox-item:contains(${text})`);
    this.items = this.items.filter((item) => item.text !== text);
    item.remove();
  }

  private coerce(controls: HTMLElement | JQuery<HTMLElement> | string) {
    if (typeof controls === 'string') {
      return $<HTMLInputElement>(controls);
    } else {
      return $<HTMLInputElement>(controls as HTMLInputElement);
    }
  }

  private onClick($controls: JQuery<HTMLInputElement>) {
    if ($controls && $controls.attr('checked')) {
      $controls.removeAttr('checked');
      $controls.trigger('change');
    } else {
      $controls.attr('checked', 'checked');
      $controls.trigger('change');
    }
  }
}