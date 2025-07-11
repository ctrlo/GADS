/**
 * Modal observable class
 */
class Modal {
  /**
   * @type {Array<modalSubscriber>}
   */
  observers = []

  /**
   * @typedef modalSubscriber 
   * @property {(frameNr:*, clearFields:*, id:*)=>void} handleActivate Handle activation of a modal frame
   * @property {(frame:*)=>void} handleAdd Handle addition of a modal frame
   * @property {(frame:*)=>void} handleBack Handle going back in modal frames
   * @property {(frame:*)=>void} handleNext Handle going to the next modal frame
   * @property {(modal:*)=>void} handleShow Handle showing a modal
   * @property {()=>void} handleSave Handle saving the modal
   * @property {(data:*)=>void} handleUpload Handle uploading data in the modal
   * @property {(arr:*)=>void} handleClear Handle clearing an array in the modal
   * @property {()=>void} handleClose Handle closing the modal
   * @property {(frameNr:*)=>void} handleSkip Handle skipping a modal frame
   * @property {()=>void} handleValidate Handle validating the modal
   * @property {(frame:*)=>void} handleUpdate Handle updating a modal frame
   */

  /**
   * Method for subscribing to, or "observing" observable
   * @param {modalSubscriber} subscriber - The subscriber object
   */
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  /**
   * Method for unsubscribing from observable
   * @param {*} subscriber The subscriber object to remove
   */
  unsubscribe(subscriber) {
    var index = this.observers.indexOf(subscriber)
    this.observers.splice(index, 1)
  }

  /**
   * Handle Activate
   * @param {*} frameNr The frame number
   * @param {*} clearFields Whether to clear the fields
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
