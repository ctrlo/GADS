/**
 * Observable object for sidebar
 */
class SidebarObservable {
  observers = []
  
  /**
   * Add a subscriber to the observable
   * @param {*} subscriber The subscriber to add
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Add a function to the observable
   * @param {()=>void} func The function to apply to the subscribers
   */
  addSubscriberFunction(func) {
    this.observers.push({
      handleSideBarChange: func
    })
  }

  /**
   * Handle the change event for the sidebar
   */
  sideBarChange() {
    this.observers.forEach(item => item.handleSideBarChange?.())
  }
}

/**
 * Singleton instance of SidebarObservable
 */
const sidebarObservable = new SidebarObservable()

export {
  SidebarObservable,
  sidebarObservable
}


