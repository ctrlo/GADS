import { Component } from 'component'

class RecordPopupComponent extends Component {

  constructor(element)  {
    super(element)
    this.modal = $.find('#readMore')
    this.initRecordPopup()
  }

  initRecordPopup() {
    $(this.element).on('click keydown', (ev) => {
      if (ev.type === 'click' || (ev.type === 'keydown' && (ev.which === 13 || ev.which === 32))) {
        this.handleClick(ev);
      }
    });
  }

  handleClick(ev) {
    const record_id = $(this.element).data('record-id')
    const version_id = $(this.element).data('version-id')
    const modalBody = $(this.modal).find('.modal-body')
    let url = `/record_body/${record_id}`

    ev.preventDefault()

    if (version_id) { url = `${url}?version_id=${version_id} `}

    modalBody.text('Loading...')
    modalBody.load(url)

    $(this.modal).modal('show')

    // Stop the clicking of this pop-up modal causing the opening of the
    // overall record for edit in the data table
    ev.stopPropagation()
  }
}

export default RecordPopupComponent
