import { modal } from '../../../lib/modal'
import ModalComponent from '../../../lib/component'

class UserModalComponent extends ModalComponent {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.emailField = this.el.find('input[name="email"]')
    this.emailText = this.el.find('.js-email')
    
    this.initUserModal()
  }

  // Initialize the modal
  initUserModal() {
    this.el.on('show.bs.modal', (ev) => { 
      this.toggleContent(ev)
      modal.validate() 
      this.emailField.keyup( () => { this.updateEmail() })
    })
  }

  // Toggle the right content (add user or approve account)
  toggleContent(ev) {
    if ($(ev.relatedTarget).hasClass('btn-add')) {
      modal.clear()
      this.el.find('.js-approve-account').hide()
      this.el.find('.js-add-user').show()
      this.el.find('.btn-js-reject-request').hide()
      this.el.find('.btn-js-save .btn__title').html('Create account')
      this.el.find('input[name="approve-account"]').val('false')
    } else {
      this.el.find('.js-add-user').hide()
      this.el.find('.js-approve-account').show()
      this.el.find('.btn-js-reject-request').show()
      this.el.find('.btn-js-save .btn__title').html('Approve account')
      this.el.find('input[name="approve-account"]').val('true')
    }
  }

  // Update the text container for the email address
  updateEmail() {
    this.emailText.html(this.emailField.val())
  }

  // Get all data from all fields in the modal
  getData() {
    let data = {
      view_limits: [],
      permissions: [],
      groups: []
    }

    const fieldSets = this.el.find('fieldset[data-name="view_limits"], fieldset[data-name="permissions"], fieldset[data-name="groups"]')
    const fields = this.el.find('input, textarea')
    
    // find all fields that are inside a fieldset
    fieldSets.each((i, fieldSet) => {
      const fieldSetName = $(fieldSet).data('name') || ""
      const fields = $(fieldSet).find('input')

      fields.each((i,field) => { 
        const fieldValue = isNaN($(field).val()) ? $(field).val() : parseInt($(field).val())

        if ($(field).prop('type') === 'checkbox') {
          if ($(field).prop('checked')) {
            data[fieldSetName].push(fieldValue)
          }
        } else {
          if ($(field).val()) {
            data[fieldSetName].push(fieldValue)
          }
        }
        
      })
    }) 

    // find all other fields
    fields.each((i, field) => {
      if ((!$(field).closest('fieldset[data-name="view_limits"]').length) &&
        (!$(field).closest('fieldset[data-name="permissions"]').length) &&
        (!$(field).closest('fieldset[data-name="groups"]').length)) {
        if ($(field).val() !== '') {
          const fieldValue = $(field).val()
          const fieldParsedValue = isNaN(fieldValue) ? this.parseValue(fieldValue) : parseInt(fieldValue)
          data[$(field).attr('name')] = fieldParsedValue
        }
      }
    })
    return data
  }

  parseValue(val) {
    return val === 'true' ? true : val === 'false' ? false : val 
  }

  // Handle save
  handleSave() {
    modal.upload(this.getData())
  }

  // Handle close
  handleClose() {
    super.handleClose()
    this.emailText.html("USER")
  }
}

export default UserModalComponent
