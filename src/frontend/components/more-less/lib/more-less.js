/**
 * MoreLess is a class manage observers of the more/less functionality.
 */
class MoreLess {
    /**
     * Creates an instance of MoreLess.
     */
    constructor() {
        this.observers = [];
    }


    /**
     * Adds a subscriber to the MoreLess observable.
     * @param {object} subscriber The subscriber to add.
     */
    addSubscriber(subscriber) {
        this.observers.push(subscriber);
    }

    /**
     * Unsubscribes a subscriber from the MoreLess observable.
     * @param {object} subscriber The subscriber to remove.
     */
    unsubscribe(subscriber) {
        var index = this.observers.indexOf(subscriber);
        this.observers.splice(index, 1);
    }

    /**
     * Notifies all observers to reinitialize the more/less functionality.
     */
    reinitialize() {
        this.observers.forEach(item => item.reInitMoreLess?.());
    }
}

const moreLess = new MoreLess;

export { moreLess };
