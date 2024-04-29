import {Component} from 'component'

/**
 * Button component
 * @extends Component
 */
class ButtonComponent extends Component {
    /**
     * Create a button component
     * @param element {HTMLElement} The button element
     */
    constructor(element:HTMLElement) {
        super(element)
        this.initButton(element)
    }

    /**
     * Initialize the button
     * @param element {HTMLElement} The button element
     */
    initButton(element:HTMLElement) {
        const el:JQuery<HTMLElement> = $(element)
        switch (true) {
            case el.hasClass('btn-js-report'):
                import(/* webpackChunkName: "create-report-button" */ './create-report-button')
                    .then(({default: CreateReportButtonComponent}) => {
                        new CreateReportButtonComponent(el)
                    });
                break
            case el.hasClass('btn-js-more-info'):
                import(/* webpackChunkName: "more-info-button" */ './more-info-button')
                    .then(({default: createMoreInfoButton}) => {
                        createMoreInfoButton(el)
                    });
                break
            case el.hasClass('btn-js-delete'):
                import(/* webpackChunkName: "delete-button" */ './delete-button')
                    .then(({default: createDeleteButton}) => {
                        createDeleteButton(el);
                    });
                break
            case el.hasClass('btn-js-submit-field'):
                import(/* webpackChunkName: "submit-field-button" */ "./submit-field-button")
                    .then(({default: SubmitFieldButtonComponent}) => {
                        new SubmitFieldButtonComponent(el);
                    });
                break
            case el.hasClass('btn-js-add-all-fields'):
                import(/* webpackChunkName: "add-all-fields-button" */ './add-all-fields-button')
                    .then(({default: createAddAllFieldsButton}) => {
                        createAddAllFieldsButton(el);
                    });
                break
            case el.hasClass('btn-js-submit-draft-record'):
                import(/* webpackChunkName: "submit-draft-record-button" */ './submit-draft-record-button')
                    .then(({default: createSubmitDraftRecordButton}) => {
                        createSubmitDraftRecordButton(el);
                    });
                break
            case el.hasClass('btn-js-submit-record'):
                import(/* webpackChunkName: "submit-record-button" */ './submit-record-button')
                    .then(({default: SubmitRecordButtonComponent}) => {
                        new SubmitRecordButtonComponent(el);
                    });
                break
            case el.hasClass('btn-js-save-view'):
                import(/* webpackChunkName: "save-view-button" */ './save-view-button')
                    .then(({default: SaveViewButtonComponent}) => {
                        new SaveViewButtonComponent(el);
                    });
                break
            case el.hasClass('btn-js-show-blank'):
                import(/* webpackChunkName: "show-blank-button" */ './show-blank-button')
                    .then(({default: createShowBlankButton}) => {
                        createShowBlankButton(el);
                    });
                break
            case el.hasClass('btn-js-curval-remove'):
                import(/* webpackChunkName: "curval-remove-button" */ './remove-curval-button')
                    .then(({default: createRemoveCurvalButton}) => {
                        createRemoveCurvalButton(el);
                    });
                break
        }

        if (el.hasClass('btn-js-remove-unload')) {
            import(/* webpackChunkName: "remove-unload-button" */ './remove-unload-button')
                .then(({default: createRemoveUnloadButton}) => {
                    createRemoveUnloadButton(el);
                });
        }
    }
}

export default ButtonComponent
