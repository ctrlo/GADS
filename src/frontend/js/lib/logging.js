import { uploadMessage } from 'util/scriptErrorHandler';

/**
 * Class to manage logging in the application.
 * It will log to the console if the application is running in a development environment,
 * and will upload the logs to the server if it's running in production.
 */
class Logging {
    /**
     * Initializes the logging class and determines if logging is allowed based on the environment.
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
            console.log(message);
        } else {
            const message = this.formatMessage('log', ...message);
            uploadMessage(message);
        }
    }

    /**
     * Logs an info message to the console if logging is allowed.
     * @param  {...any} message - The message to log as an info
     */
    info(...message) {
        if (this.allowLogging) {
            console.info(message);
        } else {
            const message = this.formatMessage('info', ...message);
            uploadMessage(message);
        }
    }

    /**
     * Logs a warning message to the console if logging is allowed.
     * @param  {...any} message - The message to log as a warning
     */
    warn(...message) {
        if (this.allowLogging) {
            console.warn(message);
        } else {
            const message = this.formatMessage('warn', ...message);
            uploadMessage(message);
        }
    }

    /**
     * Logs an error message to the console if logging is allowed.
     * @param  {...any} message - The message to log as an error
     */
    error(...message) {
        if (this.allowLogging) {
            console.error(message);
        } else {
            const message = this.formatMessage('error', ...message);
            uploadMessage(message);
        }
    }

    /**
     * Formats a message by prefixing it with the log type and converting any objects to JSON strings.
     */
    formatMessage(type, ...message) {
        let output = type + ': ';
        for (let i = 0; i < message.length; i++) {
            if (typeof message[i] === 'object') {
                output += JSON.stringify(message[i]);
            } else {
                // This is wrapped so that anything that's not an object is converted to a string
                output += `${message[i]}`;
            }
            if (i < message.length - 1) output += ' ';
        }
        return output;
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
