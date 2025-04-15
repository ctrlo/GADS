class SidebarObservable {
  constructor() {
    this.observers = []
  }

  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  sideBarChange() {
    this.observers.forEach(item => item.handleSideBarChange?.())
  }
}

const sidebarObservable = new SidebarObservable

export {
  SidebarObservable,
  sidebarObservable
}


