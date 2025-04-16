/**
 * Modal observable class
 */
class Modal {
  observers = []

  /**
   * Method for subscribing to, or "observing" observable
   * @param {*} subscriber - The subscriber object
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Method for unsubscribing from observable
   * @param {*} subscriber The subscriber object to remove
   */
  unsubscribe(subscriber) {
    const index = this.observers.indexOf(subscriber);
    this.observers.splice(index, 1)
  }

  /**
   * Handle Activate
   * @param {*} frameNr The frame number
   * @param {number} clearFields Whether to clear the fields
   * @param {*} id The ID
   */
  activate(frameNr, clearFields, id) {
    this.observers.forEach(item => item.handleActivate?.(frameNr, clearFields, id))
  }

  /**
   * Handle Add
   * @param {*} frame The frame object
   */
  add(frame) {
    this.observers.forEach(item => item.handleAdd?.(frame))
  }

  /**
   * Handle Back
   * @param {*} frame The frame object
   */
  back(frame) {
    this.observers.forEach(item => item.handleBack?.(frame))
  }

  /**
   * Handle Next
   * @param {*} frame The frame object
   */
  next(frame) {
    this.observers.forEach(item => item.handleNext?.(frame))
  }

  /**
   * Handle Show
   * @param {*} modal The modal object
   */
  show(modal) {
    this.observers.forEach(item => item.handleShow?.(modal))
  }

  /**
   * Handle Save
   */
  save() {
    this.observers.forEach(item => item.handleSave?.())
  }

  /**
   * Handle Upload
   * @param {*} data The data object
   */
  upload(data) {
    this.observers.forEach(item => item.handleUpload?.(data))
  }

  /**
   * Handle Clear
   * @param {*} arr The array to clear
   */
  clear(arr) {
    this.observers.forEach(item => item.handleClear?.(arr))
  }

  /**
   * Handle Close
   */
  close() {
    this.observers.forEach(item => item.handleClose?.())
  }

  /**
   * Handle Skip
   * @param {*} frameNr The frame number
   */
  skip(frameNr) {
    this.observers.forEach(item => item.handleSkip?.(frameNr))
  }

  /**
   * Handle Validate
   */
  validate() {
    this.observers.forEach(item => item.handleValidate?.())
  }

  /**
   * Handle Update
   * @param {*} frame The frame object
   */
  update(frame) {
    this.observers.forEach(item => item.handleUpdate?.(frame))
  }
}

/**
 * Modal instance - singleton
 */
const modal = new Modal

export {
  Modal,
  modal
}
