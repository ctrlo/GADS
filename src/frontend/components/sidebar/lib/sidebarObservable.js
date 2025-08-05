/**
 * SidebarObservable class to manage subscribers for sidebar changes.
 */
class SidebarObservable {
    /**
     * Creates an instance of SidebarObservable.
     */
    constructor() {
        this.observers = [];
    }

    /**
     * Adds a subscriber to the observers list.
     * @param {object} subscriber The subscriber object that will handle sidebar changes.
     */
    addSubscriber(subscriber) {
        this.observers.push(subscriber);
    }

    /**
     * Trigger sidebar change event for all subscribers.
     */
    sideBarChange() {
        this.observers.forEach(item => item.handleSideBarChange?.());
    }
}

const sidebarObservable = new SidebarObservable;

export { sidebarObservable };


