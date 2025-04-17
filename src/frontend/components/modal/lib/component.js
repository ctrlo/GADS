import { Component } from 'component'
import { modal } from './modal'
import { Frame } from './frame'
import { logging } from 'logging'

/**
 * Base modal component
 */
class ModalComponent extends Component {

  static get allowReinitialization() { return true }

  /**
   * Create a new bas modal component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.isWizzard = this.el.hasClass('modal--wizzard')
    this.isForm = this.el.hasClass('modal--form')
    this.frames = this.el.find('.modal-frame')
    this.typingTimer = null
    if (!this.wasInitialized) this.initModal()
  }

  /**
   * Initialize the modal
   */
  initModal() {
    this.el.on('show.bs.modal', () => {
      modal.addSubscriber(this)

      if (this.isWizzard) {
        try {
          this.activateFrame(1, 0)
        } catch (e) {
          logging.error(e)
          this.preventModalToOpen()
        }

        this.el.on('hide.bs.modal', (e) => {
          if (this.dataHasChanged()) {
            if (!confirm('Are you sure you want to close this popup? Any unsaved data will be lost.')) {
              e.preventDefault()
            }
          }
        })
      }

      if ((this.isWizzard) || (this.isForm)) {
        this.el.on('hidden.bs.modal', () => {
          this.el.off('hide.bs.modal')
          modal.close()
        })
      }

      this.hideContent(true)
    })
  }

  /**
   * Check if the data has changed
   * @returns {boolean} true if the data has changed, false otherwise
   */
  dataHasChanged() {
    const fields = $(this.el).find('input, textarea')
    let hasChanged = false

    fields.each((i, field) => {
      if ($(field).val()) {
        if (($(field).attr('type') !== 'hidden' && $(field).attr('type') !== 'checkbox' && $(field).attr('type') !== 'radio') ||
          ($(field).attr('type') === 'hidden' && $(field).parents('.select').length)) {
          if (($(field).data('original-value') && $(field).val().toString() !== $(field).data('original-value').toString()) ||
            !$(field).data('original-value')) {
            hasChanged = true
            return false
          }
        } else if ($(field).attr('type') !== 'hidden' && (($(field).data('original-value') && $(field).prop('checked') && $(field).val() !== $(field).data('original-value').toString()) ||
          (!$(field).data('original-value') && $(field).prop('checked')))) {
          hasChanged = true
          return false
        }
      }
    })

    return hasChanged
  }

  /**
   * Hidel the content if required
   * @param {boolean} bHide True to hide the content, false to show it
   */
  hideContent(bHide) {
    if (bHide) {
      $('body').children().attr('aria-hidden', true)
    } else {
      $('body').children().removeAttr('aria-hidden')
    }
  }

  /**
   * Prevent the modal from opening
   */
  preventModalToOpen() {
    const modalId = this.el.attr('id') || ""
    $(`.btn[data-target="#${modalId}"]`).on('click', function (e) {
      e.stopPropagation()
    });
  }

  /**
   * Clear all fields of the current frame
   * @param {*} frame The frame object
   */
  clearFields(frame) {
    const fields = $(frame).find('input, textarea')

    fields.each((i, field) => {
      const $field = $(field)

      if ($field.attr('type') === 'radio') {
        // Simple removal of checked property will suffice
        $field.prop('checked', false)
      } else if ($field.attr('type') === 'checkbox') {
        // Need to trigger click event to ensure widget is updated
        if ($field.is(':checked')) $field.trigger('click')
      } else {
        if ($field.data('restore-value')) {
          $field.val($field.data('restore-value'))
        } else {
          $field.val('')
        }
        $(field).removeData('original-value')
        $field.trigger('change')
      }

      if ($field.is(':invalid')) {
        $field.attr('aria-invalid', false)
        $field.closest('.input').removeClass('input--invalid')
      }
    })
  }

  /**
   * Clear all fields in specified frames
   * @param {number[]} arrFrameNumbers An array of the frames to clear
   */
  clearFrames(arrFrameNumbers) {
    if (arrFrameNumbers) {
      $(arrFrameNumbers).each((i, frameNr) => {
        const frame = this.getFrameByNumber(frameNr)
        frame && this.clearFields(frame)
      })
    } else {
      this.frames.each((i, frame) => {
        this.clearFields(frame)
      })
    }
  }

  /**
   * Get the frame number from the frame object
   * @param {*} frame The frame to get the number for
   * @returns The frame number
   */
  getFrameNumber(frame) {
    const config = $(frame).data('config')

    if (!config.frame || isNaN(config.frame)) {
      return
    }

    return config.frame
  }

  /**
   * Get the frame object by frame number
   * @param {*} frameNr The frame number
   * @returns The frame object
   */
  getFrameByNumber(frameNr) {
    let selectedFrame = null

    this.frames.each((i, frame) => {
      const config = $(frame).data('config')

      if (config.frame === frameNr) {
        selectedFrame = frame
        return false
      }
    })

    return selectedFrame
  }

  /**
   * Activate a frame by it's number
   * @param {*} frameNumber The frame number
   * @param {*} previousFrameNumber The previous frame number
   * @param {*} clearFields Whether to clear the fields or not
   */
  activateFrame(frameNumber, previousFrameNumber, clearFields) {
    this.frames.each((i, frame) => {
      const config = $(frame).data('config')

      if (!config.frame || isNaN(config.frame)) {
        throw 'activateFrame: frame is not a number!'
      }

      this.unbindEventHandlers($(frame))

      if (config.frame === frameNumber) {
        try {
          this.frame = this.createFrame(frame, previousFrameNumber)
        } catch (e) {
          logging.error(e)
        }

        this.frame.object.removeClass('invisible')
        this.frame.object.find('.alert').hide()
        this.activateStep(this.frame.step)
        this.bindEventHandlers()

        if (this.frame.requiredFields.length) {
          this.frame.buttons.next && this.setNextButtonState(false)
          this.frame.buttons.invisible && this.setInvisibleButtonState(false)
        }

        if (clearFields) {
          this.clearFields(frame)
          this.validateFrame()
        }

      } else {
        $(frame).addClass('invisible')
      }
    })
  }

  /**
   * Create a new frame object
   * @param {*} frame The frame element
   * @param {*} previousFrameNumber The previous frame number
   * @returns A frame object
   */
  createFrame(frame, previousFrameNumber) {
    if (isNaN($(frame).data('config').step) || (isNaN($(frame).data('config').frame))) {
      throw 'createFrame: Parameter is not a number!'
    }
    if ($(frame).data('config').skip && isNaN($(frame).data('config').skip)) {
      throw 'createFrame: Skip parameter is not a number!'
    }
    return new Frame($(frame), previousFrameNumber)
  }

  /**
   * Add event listeners to the buttons and required fields of the current frame
   */
  bindEventHandlers() {
    this.frame.buttons.next.click(() => { modal.next(this.frame.object) })
    this.frame.buttons.back.click(() => { modal.back(this.frame.object) })
    this.frame.buttons.skip.click(() => { this.frame.skip && modal.skip(this.frame.skip) })
    this.frame.buttons.addNext.click(() => { modal.add(this.frame.object) })
    this.frame.buttons.save.click(() => { modal.save() })
    this.frame.requiredFields.bind('keyup.modalEvent', (ev) => { this.handleKeyup(ev) })
    this.frame.requiredFields.bind('keydown.modalEvent', () => { this.handleKeydown() })
    this.frame.requiredFields.bind('blur.modalEvent', (ev) => { this.handleBlur(ev) })
  }

  /**
   * Handle the keyup event
   * @param {JQuery.Event} ev The event object
   */
  handleKeyup(ev) {
    const doneTypingInterval = 1000
    const field = ev.target
    clearTimeout(this.typingTimer)

    this.typingTimer = setTimeout(() => {
      if ($(field).val())
        this.validateField(field)
    },
      doneTypingInterval)
  }

  /**
   * Handle the keydown event
   */
  handleKeydown() {
    clearTimeout(this.typingTimer)
  }

  /**
   * Handle the blur event
   * @param {JQuery.Event} ev The event object
   */
  handleBlur(ev) {
    const field = ev.target
    clearTimeout(this.typingTimer)

    if ($(field).val())
      this.validateField(field)
  }

  /**
   * Check if a field is valid
   * @param {*} field The field to checkt
   * @returns {boolean} True if the field is valid, false otherwise
   */
  isValidField(field) {
    return !(($(field).is(':invalid')) || ($(field).val() === ""));
  }

  /**
   * Validate a single field
   * @param {*} field The field object
   */
  validateField(field) {
    const isValid = this.isValidField(field)
    this.frame.error = []

    if (!isValid) {
      const fieldLabel = $(field).closest('.input').find('label').html()
      this.frame.error.push(`${fieldLabel} is invalid`)
    }

    this.setInputState($(field), isValid)
    this.validateFrame()
  }

  /**
   * Validate the required fields of the frame
   */
  validateFrame() {
    if (!this.frame) return;
    this.frame.isValid = true

    this.frame.requiredFields.each((i, field) => {
      if (!this.isValidField($(field))) {
        this.frame.isValid = false
      }
    })

    this.setFrameState()
  }

  /**
   * Set the input state of a field
   * @param {JQuery} $field The field object
   */
  setInputState($field) {
    if ($field.is(':invalid')) {
      $field.attr('aria-invalid', true)
      $field.closest('.input').addClass('input--invalid')
    } else {
      $field.attr('aria-invalid', false)
      $field.closest('.input').removeClass('input--invalid')
    }
  }

  /**
   * Set the frame state
   */
  setFrameState() {
    const alert = this.frame.object.find('.alert')

    this.frame.buttons.next && this.setNextButtonState(this.frame.isValid)
    this.frame.buttons.invisible && this.setInvisibleButtonState(this.frame.isValid)

    if ((!this.frame.isValid) && (this.frame.error.length > 0)) {
      const errorIntro = "<p>There were problems with the following fields:</p>"
      let errorList = ""

      $.each(this.frame.error, (i, errorMsg) => {
        const errorMsgHtml = $('<span>').text(errorMsg).html()
        errorList += `<li>${errorMsgHtml}</li>`
      })

      alert.html(`<div>${errorIntro}<ul>${errorList}</ul></div>`)
      alert.show()
      this.el.animate({ scrollTop: alert.offset().top }, 500)
    } else {
      alert.hide()
    }
  }

  /**
   * Unbind event handlers from all elements of this frame
   * @param {*} frame The frame object
   */
  unbindEventHandlers(frame) {
    frame.find('.modal-footer .btn').unbind()
    frame.find('input[required]').unbind('.modalEvent')
  }

  /**
   * Set the state of the next button
   * @param {boolean} valid Whether the frame is valid or not
   */
  setNextButtonState(valid) {
    if (valid) {
      this.frame.buttons.next.removeAttr('disabled')
      this.frame.buttons.next.removeClass('btn-disabled')
      this.frame.buttons.next.addClass('btn-default')
    } else {
      this.frame.buttons.next.attr('disabled', 'disabled')
      this.frame.buttons.next.addClass('btn-disabled')
      this.frame.buttons.next.removeClass('btn-default')
    }
  }

  /**
   * Set the state of the invisible button
   * @param {boolean} valid Whether the frame is valid or not
   */
  setInvisibleButtonState(valid) {
    if (valid) {
      this.frame.buttons.invisible.removeClass('btn-invisible')
    } else {
      this.frame.buttons.invisible.addClass('btn-invisible')
    }
  }

  /**
   * Activate the current step in the header of the modal
   * @param {*} currentStep The current step to highlight
   */
  activateStep(currentStep) {
    let steps = this.el.find('.modal__step')

    steps.each((i, step) => {
      if ($(step).data('step') === currentStep) {
        $(step).addClass('modal__step--active')
      } else {
        $(step).removeClass('modal__step--active')
      }
    })
  }

  /**
   * Handle upload to server
   * @param {*} dataObj The data object to upload
   */
  handleUpload(dataObj) {
    const self = this;
    const url = this.el.data('config').url
    const id = this.el.data('config').id
    const csrf = $('body').data('csrf').toString()
    dataObj['csrf_token'] = csrf || ""
    const dataStr = JSON.stringify(dataObj)
    const strURL = id ? `${url}/${id}` : url

    $.ajax({
      method: "POST",
      contentType: "application/json",
      url: strURL,
      data: dataStr,
      processData: false
    })
      .done(function () {
        location.reload()
      })
      .fail(function (jqXHR) {
        const strError = jqXHR.responseJSON.message
        self.showError(strError)
      })
  }

  /**
   * Show an error message
   * @param {string} strError The error message
   */
  showError(strError) {
    const alert = this.frame.object.find('.alert')

    const strErrorHtml = $('<span>').text(strError).html()
    alert.html(`<p>Error: ${strErrorHtml}</p>`)
    alert.show()
    this.el.animate({ scrollTop: alert.offset().top }, 500)
  }

  /**
   * Handle next
   */
  handleNext() {
    const nextFrameNumber = this.frame.number + 1
    if (this.frames.length >= (nextFrameNumber)) {
      this.activateFrame(nextFrameNumber, this.frame.number)
    }
  }

  /**
   * Handle back
   */
  handleBack() {
    const previousFrameNumber = this.frame.back
    if (previousFrameNumber > 0) {
      this.activateFrame(this.frame.back, this.frame.back - 1)
    }
    this.validateFrame()
  }

  /**
   * Handle skip
   */
  handleSkip(skipToNumber) {
    this.activateFrame(skipToNumber, this.frame.number)
  }

  /**
   * Handle add
   * @param {*} frame The frame object
   */
  handleAdd(frame) {
    modal.update(frame)
    this.clearFields(frame)
    this.validateFrame()
  }

  /**
   * Handle activate
   * @param {*} frameNumber The frame number to activate
   * @param {boolean} clearFields Whether to clear the fields or not
   */
  handleActivate(frameNumber, clearFields) {
    this.activateFrame(frameNumber, this.frame.number, clearFields)
  }

  /**
   * Handle show
   * @param {*} modal The modal to show
   */
  handleShow(modal) {
    $(modal).modal('show')
  }

  /**
   * Handle clear
   * @param {number[]} arr An array of frame numbers to clear
   */
  handleClear(arr) {
    this.clearFrames(arr)
  }

  /**
   * Handle validate
   */
  handleValidate() {
    this.validateFrame()
  }

  /**
   * Handle close
   */
  handleClose() {
    this.clearFrames()

    if (this.isWizzard) {
      // activate first frame
      this.activateFrame(1, 0, true)

      // Clear the id in the data-config
      if (this.el.data('config') && this.el.data('config').id) {
        this.el.data('config').id = null
      }
    }

    // Remove binded events and subscribers
    this.el.off('hide.bs.modal hidden.bs.modal')
    modal.unsubscribe(this)
  }
}

export default ModalComponent
