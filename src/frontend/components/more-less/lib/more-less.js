class MoreLess {
  observers = []

  /**
   * Method for subscribing to, or "observing" observable
   * @param {*} subscriber - The object that wants to observe the observable
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Method for unsubscribing from observable
   * @param {*} subscriber - The object that wants to stop observing the observable
   */
  unsubscribe(subscriber) {
    const index = this.observers.indexOf(subscriber);
    this.observers.splice(index, 1)
  }

  /**
   * Reinitialize
   */
  reinitialize() {
    this.observers.forEach(item => item.reInitMoreLess?.())
  }
}

/**
 * Singleton instance of MoreLess
 */
const moreLess = new MoreLess

export { moreLess }
