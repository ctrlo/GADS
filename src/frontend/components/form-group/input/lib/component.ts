import {Component} from "component";
import passwordComponent from "./passwordComponent";
import logoComponent from "./logoComponent";
import documentComponent from "./documentComponent";
import fileComponent from "./fileComponent";
import dateComponent from "./dateComponent";
import autocompleteComponent from "./autocompleteComponent";
import {initValidationOnField} from "validation";

type ComponentInitializer = (element: JQuery<HTMLElement> | HTMLElement) => void;

class InputComponent extends Component {
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

    for (const [className, initializer] of Object.entries(InputComponent.componentMap)) {
      if ($el.hasClass(className)) {
        initializer(this.element);
        break; // Assuming only one component type per element
      }
    }
  }

  private initializeValidation() {
    const $el = $(this.element);

    if ($el.hasClass('input--required')) {
      initValidationOnField($el);
    }
  }
}

export default InputComponent;
