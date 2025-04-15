/**
 * A frame object
 * @prop {jQuery} object - The jQuery object of the frame
 * @prop {number} step - The step number of the frame
 * @prop {number} number - The frame number
 * @prop {string} item - The item name of the frame
 * @prop {*} skip - How many to skip
 * @prop {number} back - The previous frame number
 * @prop {jQuery} requiredFields - The required fields in the frame
 * @prop {boolean} isValid - Whether the frame is valid
 * @prop {Array} error - The errors in the frame
 * @prop {Object} buttons - The buttons in the frame
 */
class Frame {
  /**
   * Create a new frame
   * @param {*} frame The frame object
   * @param {*} previousFrameNumber The previous frame number
   */
  constructor(frame, previousFrameNumber) {
    this.object = frame
    this.step = frame.data('config').step
    this.number = frame.data('config').frame
    this.item = frame.data('config').item || null
    this.skip = frame.data('config').skip || null
    this.back = previousFrameNumber
    this.requiredFields = frame.find('input[required]')
    this.isValid = true
    this.error = []
    this.buttons = {
      next: frame.find('.modal-footer .btn-js-next'),
      back: frame.find('.modal-footer .btn-js-back'),
      skip: frame.find('.modal-footer .btn-js-skip'),
      addNext: frame.find('.modal-footer .btn-js-add-next'),
      invisible: frame.find('.modal-footer .btn-js-add-next'),
      save: frame.find('.modal-footer .btn-js-save')
    }
  }
}

export { Frame }
