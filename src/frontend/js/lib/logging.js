import { MessageUploader } from "util/scriptErrorHandler/lib/MessageUploader";
import { Uploader } from "util/upload/UploadControl";

// Exported for testing
export class Logging {
  /**
   * Create a new Logging instance.
   * @param {boolean} overrideAllowLogging True to force allowing of logging - used for testing
   */
  constructor(overrideAllowLogging = false, uploader = new MessageUploader(new Uploader('/api/script_error', 'POST'))) {
    this.uploader = uploader;
    this.allowLogging =
      window.test ||
      location.hostname === 'localhost' ||
      location.hostname === '127.0.0.1' ||
      location.hostname.endsWith('.peek.digitpaint.nl');
    if(overrideAllowLogging !== undefined) {
      this.allowLogging = overrideAllowLogging;
    }
  }

  log(...message) {
    if (this.allowLogging) {
      console.log(...message)
    } else {
      const msg = this.formatMessage('log', ...message)
      this.uploader(msg)
    }
  }

  info(...message) {
    if (this.allowLogging) {
      console.info(...message)
    } else {
      const msg = this.formatMessage('info', ...message)
      this.uploader(msg)
    }
  }

  warn(...message) {
    if (this.allowLogging) {
      console.warn(...message)
    } else {
      const msg = this.formatMessage('warn', ...message)
      this.uploader(msg)
    }
  }

  error(...message) {
    if (this.allowLogging) {
      console.error(...message)
    } else {
      const msg = this.formatMessage('error', ...message)
      this.uploader(msg)
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
export { logging }
