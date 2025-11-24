import { uploadMessage } from "util/scriptErrorHandler";

class Logging {
  constructor() {
    this.allowLogging =
      window.test ||
      location.hostname === 'localhost' ||
      location.hostname === '127.0.0.1' ||
      location.hostname.endsWith('.peek.digitpaint.nl')
  }

  log(...message) {
    if (this.allowLogging) {
      console.log(message)
    } else {
      const message = this.formatMessage('log', ...message)
      uploadMessage(message)
    }
  }

  info(...message) {
    if (this.allowLogging) {
      console.info(message)
    } else {
      const message = this.formatMessage('info', ...message)
      uploadMessage(message)
    }
  }

  warn(...message) {
    if (this.allowLogging) {
      console.warn(message)
    } else {
      const message = this.formatMessage('warn', ...message)
      uploadMessage(message)
    }
  }

  error(...message) {
    if (this.allowLogging) {
      console.error(message)
    } else {
      const message = this.formatMessage('error', ...message)
      uploadMessage(message)
    }
  }

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

const logging = new Logging
export { logging }
