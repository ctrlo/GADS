/**
 * Observable Sidebar class
 */
class SidebarObservable {
  /**
   * @type {Array} observers - Array of subscribers
   */
  observers = []

  /**
   * Add a subscriber to the observers array
   * @param {{handleSideBarChange: ()=>void}} subscriber The subscriber to add to the observers array
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Trigger the handleSideBarChange method on all subscribers
   */
  sideBarChange() {
    this.observers.forEach(item => item.handleSideBarChange?.())
  }
}

/** observable singleton */
const sidebarObservable = new SidebarObservable

export {
  SidebarObservable,
  sidebarObservable
}
