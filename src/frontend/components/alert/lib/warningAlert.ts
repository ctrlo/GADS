import { AlertBase } from "./alertBase";

/**
 * Class representing a warning alert. This class extends AlertBase to provide a specific implementation for warning alerts.
 */
export class WarningAlert extends AlertBase {
    /**
     * Create an instance of WarningAlert.
     * This class extends AlertBase to provide a specific implementation for warning alerts.
     * @param {string} message - The message to be displayed in the warning alert.
     */
    constructor(message: string) {
        super(message, "warning");
    }
}
