import { Component } from 'component';
import { BaseButton } from './base-button';

/**
 * Button component
 * @extends Component
 */
class ButtonComponent extends Component {
    /**
     * List of linked classes - this is purely for testing purposes
     * @type {string[]}
     */
    linkedClasses: string[] = [];

    private _button: BaseButton;

    /**
     * Map of button components
     * @type {Map<string, (element: JQuery<HTMLElement>) => void>}
     */
    private static staticButtonsMap: Map<string, (element: JQuery<HTMLElement>) => void>;

    /**
     * Get the map of button components
     */
    private get buttonsMap(): Map<string, (element: JQuery<HTMLElement>) => void> {
        if (!ButtonComponent.staticButtonsMap) ButtonComponent.initMap();
        return ButtonComponent.staticButtonsMap;
    }

    /**
     * Create a button component
     * @param element {HTMLElement} The button element
     */
    constructor(element: HTMLElement) {
        super(element);
        this.initButton(element);
    }

    /**
     * Initialize the map of button components
     */
    private static initMap() {
        const buttonsMap: { className: string, importPath: string }[] = [
            { className: 'btn-js-report', importPath: './create-report-button' },
            { className: 'btn-js-more-info', importPath: './more-info-button' },
            { className: 'btn-js-delete', importPath: './delete-button' },
            { className: 'btn-js-submit-field', importPath: "./submit-field-button" },
            { className: 'btn-js-toggle-all-fields', importPath: './toggle-all-fields-button' },
            { className: 'btn-js-submit-draft-record', importPath: './submit-draft-record-button' },
            { className: 'btn-js-submit-record', importPath: './submit-record-button' },
            { className: 'btn-js-save-view', importPath: './save-view-button' },
            { className: 'btn-js-show-blank', importPath: './show-blank-button' },
            { className: 'btn-js-curval-remove', importPath: './remove-curval-button' },
            { className: 'btn-js-remove-unload', importPath: './remove-unload-button' },
        ];

        const map = new Map<string, (element: JQuery<HTMLElement>) => void>();

        buttonsMap.forEach(({ className, importPath }) => {
            map.set(
                className,
                (el) => {
                    import(/* webpackChunkName: "[request]" */ `${importPath}`)
                        .then(({ default: createButtonComponent }) => {
                            createButtonComponent(el);
                        });
                }
            );
        });

        ButtonComponent.staticButtonsMap = map;
    }

    /**
     * Initialize the button
     * @param element {HTMLElement} The button element
     */
    private async initButton(element: HTMLElement) {
        const el: JQuery<HTMLElement> = $(element);
        element.classList.forEach(async (className) => {
            if (!className.startsWith('btn-js-')) return;
            if (!this.buttonsMap) throw new Error("Buttons map is not initialized");
            if (!this.buttonsMap.has(className)) return;
            this.linkedClasses.push(className);
            return this.buttonsMap.get(className)(el);
        });
    }
}

export default ButtonComponent;
