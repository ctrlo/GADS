/**
 * MoreLess observer class
 */
class MoreLess {
  observers = []

  /**
   * Method for subscribing to, or "observing" observable
   * @param {*} subscriber The subscriber to be added
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Method for unsubscribing from observable
   * @param {*} subscriber The subscriber to be removed
   */
  unsubscribe(subscriber) {
    var index = this.observers.indexOf(subscriber)
    this.observers.splice(index, 1)
  }

  /**
   * Method for reinitializing all more-less components
   */
  reinitialize() {
    this.observers.forEach(item => item.reInitMoreLess?.())
  }
}

/**
 * Exporting MoreLess class instance (singleton)
 */
const moreLess = new MoreLess

export { moreLess }


