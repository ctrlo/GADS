import { Component } from 'component';
import passwordComponent from './passwordComponent';
import logoComponent from './logoComponent';
import documentComponent from './documentComponent';
import fileComponent from './fileComponent';
import dateComponent from './dateComponent';
import autocompleteComponent from './autocompleteComponent';
import { initValidationOnField } from 'validation';

/**
 * ComponentInitializer type for functions that initialize specific input components.
 * @param {JQuery<HTMLElement> | HTMLElement} element The element to initialize the component on, can be a jQuery object or a native HTMLElement.
 */
type ComponentInitializer = (element: JQuery<HTMLElement> | HTMLElement) => void;

/**
 * InputComponent class to handle various input types.
 * It initializes the appropriate component based on the class of the element.
 */
class InputComponent extends Component {
    /**
     * Map of component class names to their respective initializers.
     * This allows for dynamic initialization of components based on the class of the element.
     * @type { Record<string, ComponentInitializer> }
     * @private
     * @static
     */
    private static componentMap: Record<string, ComponentInitializer> = {
        'input--password': passwordComponent,
        'input--logo': logoComponent,
        'input--document': documentComponent,
        'input--file': fileComponent,
        'input--datepicker': dateComponent,
        'input--autocomplete': autocompleteComponent
    };

    /**
     * Create an instance of InputComponent.
     * @param {HTMLElement | JQuery<HTMLElement>} element The HTML element or jQuery object to initialize the component on.
     */
    constructor(element: HTMLElement | JQuery<HTMLElement>) {
        super(element instanceof HTMLElement ? element : element[0]);
        this.initializeComponent();
        this.initializeValidation();
    }

    /**
     * Initializes the component based on the class of the element.
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
     * Initializes validation on the input field if it has the 'input--required' class.
     */
    private initializeValidation() {
        const $el = $(this.element);

        if ($el.hasClass('input--required')) {
            initValidationOnField($el);
        }
    }
}

export default InputComponent;
