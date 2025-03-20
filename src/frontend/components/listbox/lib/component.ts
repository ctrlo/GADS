import { Component } from "component";
import BasicListComponent from "./listboxComponent";

export default class ToggleListComponent extends Component {
  private $el: JQuery<HTMLElement>;
  private selectedList: BasicListComponent;
  private availableList: BasicListComponent;
  private elements: {id: string, index:number }[] =[];

  constructor(element: HTMLElement) {
    super(element);
    this.$el = $(element);
    this.init();
  }

  init() {
    this.selectedList = new BasicListComponent(document.getElementById('rows-selected'));
    this.availableList = new BasicListComponent(document.getElementById('rows-available'));
    this.$el.find<HTMLInputElement>('input[type="checkbox"]').each((index: number, element: HTMLInputElement) => {
      this.elements.push({id: element.id, index});
      this.addListElement(element, index, element.attributes['checked'] ? this.selectedList : this.availableList);
      $(element).on('change', (ev) => {
        this.onChange(ev);
      });
    });
  }

  private onChange(ev: JQuery.ChangeEvent) {
    if (ev.target.checked) {
      const index = this.getPlacement(ev.target);
      if(index === -1) return;
      this.addListElement(ev.target, index, this.selectedList);
      this.removeListElement(ev.target, this.availableList);
    } else {
      const index = this.getPlacement(ev.target);
      if(index === -1) return;
      this.addListElement(ev.target, index, this.availableList);
      this.removeListElement(ev.target, this.selectedList);
    }
  }

  private addListElement(element: HTMLInputElement, index: number, component: BasicListComponent) {
    component.addItem(this.getLabel(element), index, element);
  }

  private removeListElement(element: HTMLInputElement, component: BasicListComponent) {
    component.removeItem(this.getLabel(element));
  }

  private getLabel(element: HTMLInputElement) {
    return $(element).closest('div')?.find('label')?.text() || 'NO LABEL';
  }

  private getPlacement(element: HTMLInputElement) {
    return this.elements.filter((el) => {
      return el.id === element.id
    })[0].index!;
  }
}