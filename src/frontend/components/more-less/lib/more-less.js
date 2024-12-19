class MoreLess {
  // A list of observers
  constructor() {
    this.observers = []
  }

  // Method for subscribing to, or "observing" observable
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  // Method for unsubscribing from observable
  unsubscribe(subscriber) {
    const index = this.observers.indexOf(subscriber);
    this.observers.splice(index, 1)
  }

  // Reinitialize
  reinitialize() {
    this.observers.forEach(item => item.reInitMoreLess?.())
  }
}

const moreLess = new MoreLess

export {moreLess}


