import {Component} from 'component'

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
        super(element)
        this.initButton(element)
    }

    /**
     * Initialize the map of button components
     */
    private static initMap() {
        const map = new Map<string, (element: JQuery<HTMLElement>) => void>();
        map.set('btn-js-report', (el) => {
            import(/* webpackChunkName: "create-report-button" */ './create-report-button')
                .then(({default: CreateReportButtonComponent}) => {
                    new CreateReportButtonComponent(el)
                });
        });
        map.set('btn-js-more-info', (el) => {
            import(/* webpackChunkName: "more-info-button" */ './more-info-button')
                .then(({default: createMoreInfoButton}) => {
                    createMoreInfoButton(el)
                });
        });
        map.set('btn-js-delete', (el) => {
            import(/* webpackChunkName: "delete-button" */ './delete-button')
                .then(({default: createDeleteButton}) => {
                    createDeleteButton(el);
                });
        });
        map.set('btn-js-submit-field', (el) => {
            import(/* webpackChunkName: "submit-field-button" */ "./submit-field-button")
                .then(({default: SubmitFieldButtonComponent}) => {
                    new SubmitFieldButtonComponent(el);
                });
        });
        map.set('btn-js-toggle-all-fields', (el) => {
            import(/* webpackChunkName: "toggle-all-fields-button" */ './toggle-all-fields-button')
                .then(({default: createToggleAllFieldsButton}) => {
                    createToggleAllFieldsButton(el);
                });
        });
        map.set('btn-js-submit-draft-record', (el) => {
            import(/* webpackChunkName: "submit-draft-record-button" */ './submit-draft-record-button')
                .then(({default: createSubmitDraftRecordButton}) => {
                    createSubmitDraftRecordButton(el);
                });
        });
        map.set('btn-js-submit-record', (el) => {
            import(/* webpackChunkName: "submit-record-button" */ './submit-record-button')
                .then(({default: SubmitRecordButtonComponent}) => {
                    new SubmitRecordButtonComponent(el);
                });
        });
        map.set('btn-js-save-view', (el) => {
            import(/* webpackChunkName: "save-view-button" */ './save-view-button')
                .then(({default: createSaveViewButton}) => {
                    createSaveViewButton(el);
                });
        });
        map.set('btn-js-show-blank', (el) => {
            import(/* webpackChunkName: "show-blank-button" */ './show-blank-button')
                .then(({default: createShowBlankButton}) => {
                    createShowBlankButton(el);
                });
        });
        map.set('btn-js-curval-remove', (el) => {
            import(/* webpackChunkName: "curval-remove-button" */ './remove-curval-button')
                .then(({default: createRemoveCurvalButton}) => {
                    createRemoveCurvalButton(el);
                });
        });
        map.set('btn-js-remove-unload', (el) => {
            import(/* webpackChunkName: "remove-unload-button" */ './remove-unload-button')
                .then(({default: createRemoveUnloadButton}) => {
                    createRemoveUnloadButton(el);
                });
        });
        map.set('btn-js-cancel', (el) => {
            import(/* webpackChunkName: "cancel-button" */ './cancel-button')
                .then(({default: createCancelButton}) => {
                    createCancelButton(el);
                });
        });
        map.set('btn-js-chronology', (el) => {
            import(/* webpackChunkName: "chronology-button" */ './chronology-button')
                .then(({default: ChronologyButton}) => {
                    new ChronologyButton(el[0] as HTMLElement);
                });
        });
        ButtonComponent.staticButtonsMap = map;
    }

    /**
     * Initialize the button
     * @param element {HTMLElement} The button element
     */
    private initButton(element: HTMLElement) {
        const el: JQuery<HTMLElement> = $(element)
        element.classList.forEach((className) => {
            if(!className.startsWith('btn-js-')) return;
            if (!this.buttonsMap) throw "Buttons map is not initialized";
            if (!this.buttonsMap.has(className)) return;
            this.linkedClasses.push(className);
            this.buttonsMap.get(className)(el);
        });
    }
}

export default ButtonComponent
