/**
 * Frame class
 * @property {number} object - configuration object of the frame
 * @property {number} step - number of the step
 * @property {number} number - frame number
 * @property {number} item - item name of the frame
 * @property {number} skip - number of the frame to skip to
 * @property {number} back - number of the frame to go back to
 * @property {JQuery<HTMLElement>} requiredFields - required fields of the frame
 * @property {boolean} isValid - if the frame is valid
 * @property {Array} error - error messages
 * @property {object} buttons - buttons on the frame
 */
class Frame {
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
