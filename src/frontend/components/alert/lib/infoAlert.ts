import { AlertBase } from './alertBase';

export class InfoAlert extends AlertBase {
    /**
     * Create an instance of InfoAlert.
     * This class extends AlertBase to provide a specific implementation for info alerts.
     * It uses the AlertType.INFO to set the alert type.
     * @class
     * @public
     * @memberof alert.lib
     * @constructor
     * @param {string} message - The message to be displayed in the info alert.
     */
    constructor(message: string) {
        super(message, "info");
    }
}