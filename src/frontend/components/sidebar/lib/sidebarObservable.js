class SidebarObservable {
  /**
   * Add a subscriber to the observable
   * @param {*} subscriber The subscriber to add
   */
  addSubscriber(subscriber) {
    // Lazy initialization
    if (!this.observers) this.observers = []
    this.observers.push(subscriber)
  }

  /**
   * Emit the side bar change event
   */
  sideBarChange() {
    this.observers && this.observers.forEach(item => item.handleSideBarChange?.())
  }
}

const sidebarObservable = new SidebarObservable

export {
  SidebarObservable,
  sidebarObservable
}


