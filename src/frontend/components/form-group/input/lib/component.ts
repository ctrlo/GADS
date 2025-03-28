import { Component } from "component";
import passwordComponent from "./passwordComponent";
import logoComponent from "./logoComponent";
import documentComponent from "./documentComponent";
import fileComponent from "./fileComponent";
import dateComponent from "./dateComponent";
import autocompleteComponent from "./autocompleteComponent";
import { initValidationOnField } from "validation";

type ComponentInitializer = (element: JQuery<HTMLElement> | HTMLElement) => void;

/**
 * Input component
 */
class InputComponent extends Component {
    /**
     * Map of component classes to their respective initializers
     */
    private static componentMap: { [key: string]: ComponentInitializer } = {
        'input--password': passwordComponent,
        'input--logo': logoComponent,
        'input--document': documentComponent,
        'input--file': fileComponent,
        'input--datepicker': dateComponent,
        'input--autocomplete': autocompleteComponent
    };

    /**
     * Create a new input component
     * @param element The element to attach the input component to
     */
    constructor(element: HTMLElement | JQuery<HTMLElement>) {
        super(element);
        this.initializeComponent();
        this.initializeValidation();
    }

    /**
     * Initialize the input component
     */
    private initializeComponent() {
        const $el = $(this.element);

        for (const [className, initializer] of Object.entries(InputComponent.componentMap)) {
            if ($el.hasClass(className)) {
                initializer(this.element);
                break; // Assuming only one component type per element
            }
        }
    }

    /**
     * Initialize the validation on the input component
     */
    private initializeValidation() {
        const $el = $(this.element);

        if ($el.hasClass('input--required')) {
            initValidationOnField($el);
        }
    }
}

export default InputComponent;
