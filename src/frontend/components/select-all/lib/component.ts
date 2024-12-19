import {Component} from "component";

export default class SelectAllComponent extends Component {
  el: JQuery<HTMLInputElement>;

  constructor(element: HTMLElement) {
    super(element);
    this.el = $<HTMLInputElement>(element as HTMLInputElement);
    this.element.addEventListener("change", () => this.onChange());
  }

  onChange() {
    const parent = this.el.closest('fieldset');
    const boxes = parent.find("input[type=checkbox]");
    boxes.toArray().forEach(item => {
      if (item === this.el[0]) return;
      const i = <HTMLInputElement>item;
      i.checked = (<HTMLInputElement>this.el[0]).checked;
    });
  }
}