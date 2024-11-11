import { Component } from 'component';

interface ButtonDefinition {
    className: string;
    importPath: string;
}

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

    addDefinition(definition: ButtonDefinition);
    addDefinition({className, importPath}:ButtonDefinition) {
        if(!this.buttonsMap) ButtonComponent.initMap();
        if(this.buttonsMap.has(className)) throw Error(`Button definition for ${className} already exists`);
        this.buttonsMap.set(className, (el) => {
            import(/* webpackChunkName: className */ importPath)
                .then(({ default: createButton }) => {
                    createButton(el);
                });
        });
    };

    /**
     * Initialize the map of button components
     */
    private static initMap() {
        const definitions: ButtonDefinition[] = [
            { className: 'btn-js-report', importPath: './create-report-button' },
            { className: 'btn-js-more-info', importPath: './more-info-button' },
            { className: 'btn-js-delete', importPath: './delete-button' },
            { className: 'btn-js-submit-field', importPath: './submit-field-button' },
            { className: 'btn-js-toggle-all-fields', importPath: './toggle-all-fields-button' },
            { className: 'btn-js-submit-draft-record', importPath: './submit-draft-record-button' },
            { className: 'btn-js-submit-record', importPath: './submit-record-button' },
            { className: 'btn-js-save-view', importPath: './save-view-button' },
            { className: 'btn-js-show-blank', importPath: './show-blank-button' },
            { className: 'btn-js-curval-remove', importPath: './remove-curval-button' },
            { className: 'btn-js-remove-unload', importPath: './remove-unload-button' },
        ];

        const map = new Map<string, (element: JQuery<HTMLElement>) => void>();

        for (const { className, importPath } of definitions) {
            map.set(className, (el) => {
                import(/* webpackChunkName: className */ importPath)
                    .then(({ default: createButton }) => {
                        createButton(el);
                    });
            });
        }

        ButtonComponent.staticButtonsMap = map;
    }

    /**
     * Initialize the button
     * @param element {HTMLElement} The button element
     */
    private initButton(element: HTMLElement) {
        const el: JQuery<HTMLElement> = $(element);
        element.classList.forEach((className) => {
            if (!className.startsWith('btn-js-')) return;
            if (!this.buttonsMap) throw "Buttons map is not initialized";
            if (!this.buttonsMap.has(className)) return;
            this.linkedClasses.push(className);
            this.buttonsMap.get(className)(el);
        });
    }
}

export default ButtonComponent;
