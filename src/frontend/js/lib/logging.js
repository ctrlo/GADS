/**
 * Logging class to handle logging messages to the console.
 * @property {boolean} allowLogging - Flag to determine if logging is allowed.
 */
class Logging {
    /**
     * Creates an instance of Logging handler.
     */
    constructor() {
        this.allowLogging =
            window.test ||
            location.hostname === 'localhost' ||
            location.hostname === '127.0.0.1' ||
            location.hostname.endsWith('.peek.digitpaint.nl')
    }

    /**
     * Log messages to the console.
     * @param  {...any} message - Messages to log.
     */
    log(...message) {
        if (this.allowLogging) {
            console.log(message)
        }
    }

    /**
     * Log messages to the console with info level.
     * @param  {...any} message - Messages to log.
     */
    info(...message) {
        if (this.allowLogging) {
            console.info(message)
        }
    }

    /**
     * Log messages to the console with warn level.
     * @param  {...any} message - Messages to log.
     */
    warn(...message) {
        if (this.allowLogging) {
            console.warn(message)
        }
    }

    /**
     * Log messages to the console with error level.
     * @param  {...any} message - Messages to log.
     */
    error(...message) {
        if (this.allowLogging) {
            console.error(message)
        }
    }
}

/**
 * Logging instance to handle logging messages. (Singleton)
 */
const logging = new Logging

export { logging }
