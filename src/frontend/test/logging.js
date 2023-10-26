// Fake logging class for testing
class Logging {
  constructor() {
    this.allowLogging = true
  }

  log(message) {
    if (this.allowLogging) {
      console.log(message)
    }
  }

  info(message) {
    if (this.allowLogging) {
      console.info(message)
    }
  }

  warn(message) {
    if (this.allowLogging) {
      console.warn(message)
    }
  }

  error(message) {
    if (this.allowLogging) {
      console.error(message)
    }
  }
}

const logging = new Logging

export { logging }