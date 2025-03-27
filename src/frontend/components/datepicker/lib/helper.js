import 'bootstrap-datepicker'

/**
 * Initialize a date field
 * @param {*} field The field to initialize
 */
const initDateField = (field) => {
  field.datepicker({
    "format": field.data("dateformat-datepicker"),
    "autoclose": "true"
  }).on('show.bs.modal', function (event) {
    // prevent datepicker from firing bootstrap modal "show.bs.modal"
    event.stopPropagation()
  }).on('hide', (e) => {
    // prevent datepicker from firing bootstrap modal "hide.bs.modal"
    e.stopPropagation()
  })
}

export default initDateField
