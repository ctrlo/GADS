class Logging {
    constructor() {
        this.allowLogging =
            window.test ||
            location.hostname === 'localhost' ||
            location.hostname === '127.0.0.1' ||
            location.hostname.endsWith('.peek.digitpaint.nl');
    }

    log(...message) {
        if (this.allowLogging) {
            console.log(...message);
        }
    }

    info(...message) {
        if (this.allowLogging) {
            console.info(...message);
        }
    }

    warn(...message) {
        if (this.allowLogging) {
            console.warn(...message);
        }
    }

    error(...message) {
        if (this.allowLogging) {
            console.error(...message);
        }
    }
}

const logging = new Logging;
export { logging };
