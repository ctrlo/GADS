import {Component} from "component";
import passwordComponent from "./passwordComponent";
import logoComponent from "./logoComponent";
import documentComponent from "./documentComponent";
import fileComponent from "./fileComponent";
import dateComponent from "./dateComponent";
import autocompleteComponent from "./autocompleteComponent";
import {initValidationOnField} from "validation";
import InputBase from "./inputBase";

type ComponentInitializer = (element: JQuery<HTMLElement> | HTMLElement) => InputBase;

class InputComponent extends Component {
  linkedComponent: InputBase | null = null;
  isValidatationEnabled: boolean = false;

  private static componentMap: { [key: string]: ComponentInitializer } = {
    'input--password': passwordComponent,
    'input--logo': logoComponent,
    'input--document': documentComponent,
    'input--file': fileComponent,
    'input--datepicker': dateComponent,
    'input--autocomplete': autocompleteComponent
  };

  constructor(element: HTMLElement | JQuery<HTMLElement>) {
    super(element);
    this.initializeComponent();
    this.initializeValidation();
  }

  private initializeComponent() {
    const $el = $(this.element);

    this.linkedComponent = Object.entries(InputComponent.componentMap)
      .find(([className]) => $el.hasClass(className))?.[1](this.element);
  }

  private initializeValidation() {
    const $el = $(this.element);

    if ($el.hasClass('input--required')) {
      initValidationOnField($el);
      this.isValidatationEnabled = true;
    }
  }
}

export default InputComponent;
