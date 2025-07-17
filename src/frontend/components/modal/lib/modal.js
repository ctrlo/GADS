/**
 * Base class for modal handling.
 */
class Modal {
    /**
     * Constructor for the Modal class.
     */
    constructor() {
        this.observers = [];
    }

    /**
     * Method for subscribing to, or "observing" observable
     * @param {object} subscriber - The subscriber object that will handle modal events.
     */
    addSubscriber(subscriber) {
        this.observers.push(subscriber);
    }

    /**
     * Method for unsubscribing from observable
     * @param {object} subscriber - The subscriber object to be removed.
     */
    unsubscribe(subscriber) {
        var index = this.observers.indexOf(subscriber);
        this.observers.splice(index, 1);
    }

    /**
     * Handle the Activate event.
     * @param {number} frameNr - The frame number to activate.
     * @param {boolean} clearFields - Whether to clear fields.
     * @param {number} id - The ID of the modal.
     */
    activate(frameNr, clearFields, id) {
        this.observers.forEach(item => item.handleActivate?.(frameNr, clearFields, id));
    }

    /**
     * Handle Add
     * @param {JQuery<HTMLElement>} frame - The frame object to be added.
     */
    add(frame) {
        this.observers.forEach(item => item.handleAdd?.(frame));
    }

    /**
     * Handle Back
     * @param {JQuery<HTMLElement>} frame - The frame object to go back to.
     */
    back(frame) {
        this.observers.forEach(item => item.handleBack?.(frame));
    }

    /**
     * Handle Next
     * @param {JQuery<HTMLElement>} frame - The frame object to go to next.
     */
    next(frame) {
        this.observers.forEach(item => item.handleNext?.(frame));
    }

    /**
     * Handle Show
     * @param {JQuery<HTMLElement>} modal - The modal object to be shown.
     */
    show(modal) {
        this.observers.forEach(item => item.handleShow?.(modal));
    }

    /**
     * Handle Save
     */
    save() {
        this.observers.forEach(item => item.handleSave?.());
    }

    /**
     * Handle Upload
     * @param {object} data - The data to be uploaded.
     */
    upload(data) {
        this.observers.forEach(item => item.handleUpload?.(data));
    }

    /**
     * Handle Clear
     * @param {Array} arr - The array to be cleared.
     */
    clear(arr) {
        this.observers.forEach(item => item.handleClear?.(arr));
    }

    /**
     * Handle Close
     */
    close() {
        this.observers.forEach(item => item.handleClose?.());
    }

    /**
     * Handle Skip
     * @param {number} frameNr The number of the frame to skip to.
     */
    skip(frameNr) {
        this.observers.forEach(item => item.handleSkip?.(frameNr));
    }

    /**
     * Validate the modal
     */
    validate() {
        this.observers.forEach(item => item.handleValidate?.());
    }

    /**
     * Update the modal frame
     * @param {JQuery<HTMLElement>} frame The frame to update.
     */
    update(frame) {
        this.observers.forEach(item => item.handleUpdate?.(frame));
    }
}

const modal = new Modal;

export {
    Modal,
    modal
};
