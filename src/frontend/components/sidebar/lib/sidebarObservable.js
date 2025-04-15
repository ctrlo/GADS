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


