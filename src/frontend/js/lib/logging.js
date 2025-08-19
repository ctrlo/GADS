/**
 * Logging utility for debugging and information output.
 */
class Logging {
    /**
     * Creates an instance of the Logging class.
     */
    constructor() {
        this.allowLogging =
            window.test ||
            location.hostname === 'localhost' ||
            location.hostname === '127.0.0.1' ||
            location.hostname.endsWith('.peek.digitpaint.nl');
    }

    /**
     * Logs a message to the console if logging is allowed.
     * @param  {...any} message - The message to log
     */
    log(...message) {
        if (this.allowLogging) {
            console.log(...message);
        }
    }

    /**
     * Logs an info message to the console if logging is allowed.
     * @param  {...any} message - The message to log as an info
     */
    info(...message) {
        if (this.allowLogging) {
            console.info(...message);
        }
    }

    /**
     * Logs a warning message to the console if logging is allowed.
     * @param  {...any} message - The message to log as a warning
     */
    warn(...message) {
        if (this.allowLogging) {
            console.warn(...message);
        }
    }

    /**
     * Logs an error message to the console if logging is allowed.
     * @param  {...any} message - The message to log as an error
     */
    error(...message) {
        if (this.allowLogging) {
            console.error(...message);
        }
    }
}

/**
 * Singleton instance of the Logging class for use throughout the application.
 * @type {Logging}
 * @constant
 * @default
 */
const logging = new Logging();

export { logging };
