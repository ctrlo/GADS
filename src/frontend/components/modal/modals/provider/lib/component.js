import { modal } from '../../../lib/modal'
import ModalComponent from '../../../lib/component'

class ProviderModalComponent extends ModalComponent {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.providerField = this.el.find('input[name="name"]')
    this.providerText = this.el.find('.js-provider')
    this.data={};
    
    this.initProviderModal()
  }

  // Initialize the modal
  initProviderModal() {
    this.el.on('show.bs.modal', (ev) => { 
      this.toggleContent(ev)
      modal.validate() 
      this.updateProvider()
      this.providerField.on("keyup", () => { this.updateProvider() })
    });

    $('input[type="file"]').on('change', (ev)=>{
      if(ev.target.files.length === 0) return;
      const file = ev.originalEvent.target.files[0];
      const reader = new FileReader();
      reader.onload = (e) => {
        const fileContent = e.target.result;
        this.data[ev.target.name] = fileContent; // Store the file content in data
        console.log(`File ${ev.target.name} loaded:`, fileContent);
      };
      reader.readAsText(file); // Read the file as a Data URL
    });
  }

  // Toggle the right content (add user or approve account)
  toggleContent(ev) {
    if ($(ev.relatedTarget).hasClass('btn-add')) {
      modal.clear()
      this.el.find('.js-add-provider').show()
      this.el.find('.btn-js-save .btn__title').html('Create provider')
    } else {
      this.el.find('.js-add-provider').hide()
    }
  }

  // Update the text container for the provider address
  updateProvider() {
    this.providerText.html(this.providerField.val())
  }

  // Get all data from all fields in the modal
  getData() {
    const data = {
      ...this.data,
    }

    this.el.find('input, textarea').each((i, field) => {
      if($(field).prop('type')==='file') return;
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
    this.providerText.html("PROVIDER")
  }
}

export default ProviderModalComponent
