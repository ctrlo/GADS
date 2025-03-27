class Modal {
  observers = []

  /**
   * Add a subscriber to the observable
   * @param {*} subscriber The subscriber to be added
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Remove a subscriber from the observable
   * @param {*} subscriber The subscriber to be removed
   */
  unsubscribe(subscriber) {
    var index = this.observers.indexOf(subscriber)
    this.observers.splice(index, 1)
  }

  /**
   * Activate a frame
   * @param {number} frameNr Frame number
   * @param {boolean} clearFields Whether the fields need clearing
   * @param {*} id The ID of the item
   */
  activate(frameNr, clearFields, id) {
    this.observers.forEach(item => item.handleActivate?.(frameNr, clearFields, id))
  }

  /**
   * Handle the add action
   * @param {*} frame The frame to handle to action on
   */
  add(frame) {
    this.observers.forEach(item => item.handleAdd?.(frame))
  }

  /**
   * Handle the back action
   * @param {*} frame The frame to handle the back action
   */
  back(frame) {
    this.observers.forEach(item => item.handleBack?.(frame))
  }

  /**
   * Handle the next action
   * @param {*} frame The frame to handle the next action
   */
  next(frame) {
    this.observers.forEach(item => item.handleNext?.(frame))
  }

  /**
   * Handle the show action
   * @param {*} modal The modal to be shown
   */
  show(modal) {
    this.observers.forEach(item => item.handleShow?.(modal))
  }

  /**
   * Handle the save action
   */
  save() {
    this.observers.forEach(item => item.handleSave?.())
  }

  /**
   * Handle the upload action
   * @param {*} data The data to upload
   */
  upload(data) {
    this.observers.forEach(item => item.handleUpload?.(data))
  }

  /**
   * Handle the clear action
   * @param {*} arr The array to clear the fields
   */
  clear(arr) {
    this.observers.forEach(item => item.handleClear?.(arr))
  }

  /**
   * Handle the close action
   */
  close() {
    this.observers.forEach(item => item.handleClose?.())
  }

  /**
   * Handle the skip action
   * @param {number} frameNr The frame number to skip to
   */
  skip(frameNr) {
    this.observers.forEach(item => item.handleSkip?.(frameNr))
  }

  /**
   * Handle the validate action
   */
  validate() {
    this.observers.forEach(item => item.handleValidate?.())
  }

  /**
   * Handle the update action
   * @param {*} frame The frame to update
   */
  update(frame) {
    this.observers.forEach(item => item.handleUpdate?.(frame))
  }
}

/**
 * Create a new instance of the Modal class (singleton)
 */
const modal = new Modal

export { 
  Modal,
  modal
}
