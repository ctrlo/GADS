import { AlertBase } from "./alertBase";

export class SuccessAlert extends AlertBase {
    /**
     * Create an instance of InfoAlert.
     * This class extends AlertBase to provide a specific implementation for info alerts.
     * It uses the 'info' alert type for styling and behavior.
     * @class
     * @public
     * @memberof alert.lib
     * @constructor
     * @param {string} message - The message to be displayed in the alert.
     */
    constructor(message: string) {
        super(message, 'success', true);
    }
}
