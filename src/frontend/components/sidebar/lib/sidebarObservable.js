class SidebarObservable {
  constructor() {
    this.observers = []
  }

  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  addSubscriberFunction(func) {
    this.observers.push({ handleSideBarChange: func })
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


