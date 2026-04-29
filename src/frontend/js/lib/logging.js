import { uploadMessage } from 'util/scriptErrorHandler';

class Logging {
    /**
   * Create a new Logging instance.
   */
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
        } else {
            const msg = this.formatMessage('log', ...message);
            uploadMessage(msg);
        }
    }

    info(...message) {
        if (this.allowLogging) {
            console.info(...message);
        } else {
            const msg = this.formatMessage('info', ...message);
            uploadMessage(msg);
        }
    }

    warn(...message) {
        if (this.allowLogging) {
            console.warn(...message);
        } else {
            const msg = this.formatMessage('warn', ...message);
            uploadMessage(msg);
        }
    }

    error(...message) {
        if (this.allowLogging) {
            console.error(...message);
        } else {
            const msg = this.formatMessage('error', ...message);
            uploadMessage(msg);
        }
    }

    formatMessage(type, ...message) {
        let output = type + ': ';
        for (let i = 0; i < message.length; i++) {
            if(!message[i]) continue;
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

const logging = new Logging();
export { logging };
