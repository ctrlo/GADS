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
      this.updateEmail()
      this.emailField.keyup( () => { this.updateEmail() })
    })
  }

  // Toggle the right content (add user or approve account)
  toggleContent(ev) {
    this.target = $(ev.relatedTarget)
    if (this.target.hasClass('btn-add')) {
      modal.clear()
      this.el.find('.js-approve-account').hide()
      this.el.find('.js-add-user').show()
      this.el.find('.btn-js-reject-request').hide()
      this.el.find('.btn-js-save .btn__title').html('Create account')
      this.el.find('input[name="approve-account"]').val('false')
    } else {
      this.el.find('.js-add-user').hide()
      this.el.find('.js-approve-account').show()
      this.el.find('.btn-js-reject-request').show().on("click", ()=>{
        this.activateFrame(4);
      })
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
    const data = {
      view_limits: [],
      permissions: [],
      groups: []
    }

    this.el.find('input, textarea').each((i, field) => {
      if (($(field).prop('type') === 'radio' || $(field).prop('type') === 'checkbox')) {
        if ($(field).prop('checked')) {
          const fieldValue = isNaN($(field).val()) ? $(field).val() : parseInt($(field).val())
          if (Array.isArray(data[$(field).attr('name')])) {
            data[$(field).attr('name')].push(fieldValue)
          } else {
            data[$(field).attr('name')] = fieldValue
          }
        }
      } else if ($(field).val() !== '') {
        const fieldValue = $(field).val()
        const fieldParsedValue = isNaN(fieldValue) ? this.parseValue(fieldValue) : parseInt(fieldValue)
        if (Array.isArray(data[$(field).attr('name')])) {
          data[$(field).attr('name')].push(fieldParsedValue)
        } else {
          data[$(field).attr('name')] = fieldParsedValue
        }
      }
    });

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

  handleBack() {
    super.handleBack()
    if(this.target.hasClass('btn-add')) return;
    this.el.find('.btn-js-reject-request').off().on("click", ()=>{
      this.activateFrame(4);
    });
  }

  handleNext() {
    super.handleNext()
    if(this.target.hasClass('btn-add')) return;
    this.el.find('.btn-js-reject-request').off().on("click", ()=>{
      this.activateFrame(4);
    });
  }
}

export default UserModalComponent
