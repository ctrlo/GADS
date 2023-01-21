class Modal {
  // A list of observers
  constructor() {
    this.observers = []
  }

  // Method for subscribing to, or "observing" observable
  addSubscriber(subscriber) {
    this.observers.push(subscriber)
  }

  // Method for unsubscribing from observable
  unsubscribe(subscriber) {
    var index = this.observers.indexOf(subscriber)
    this.observers.splice(index, 1)
  }

  // Activate
  activate(frameNr, clearFields, id) {
    this.observers.forEach(item => item.handleActivate?.(frameNr, clearFields, id))
  }

  // Add
  add(frame) {
    this.observers.forEach(item => item.handleAdd?.(frame))
  }

  // Back
  back(frame) {
    this.observers.forEach(item => item.handleBack?.(frame))
  }

  // Next
  next(frame) {
    this.observers.forEach(item => item.handleNext?.(frame))
  }

  // Show
  show(modal) {
    this.observers.forEach(item => item.handleShow?.(modal))
  }

  // Save
  save() {
    this.observers.forEach(item => item.handleSave?.())
  }

  // Upload
  upload(data) {
    this.observers.forEach(item => item.handleUpload?.(data))
  }

  // Clear
  clear(arr) {
    this.observers.forEach(item => item.handleClear?.(arr))
  }

  // Close
  close() {
    this.observers.forEach(item => item.handleClose?.())
  }

  // Skip
  skip(frameNr) {
    this.observers.forEach(item => item.handleSkip?.(frameNr))
  }

  // Validate
  validate() {
    this.observers.forEach(item => item.handleValidate?.())
  }

  // Update
  update(frame) {
    this.observers.forEach(item => item.handleUpdate?.(frame))
  }
}

const modal = new Modal

export { 
  Modal,
  modal
}


