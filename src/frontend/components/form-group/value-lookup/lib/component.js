import { Component } from 'component'
import { getFieldValues } from "get-field-values"
import { setFieldValues } from "set-field-values"

/* Used to lookup a value at an external endpoint
 * and prefill other fields from the response */

class ValueLookupComponent extends Component {
  constructor(element)  {
    super(element)
    this.initLookupComponent()
  }

  initLookupComponent() {
    const field = this.getLookupEndpoint();
    this.setupValueLookup(field);
  }

  getLookupEndpoint() {
    const lookup_endpoint = $(this.element).data("lookup-endpoint");
    return {
      field: $(this.element),
      endpoint: lookup_endpoint,
    };
  }

  setupValueLookup(field) {
    const endpoint = field.endpoint;
    const $field = field.field;
    $field.on("change", function() {
      let name = $field.find('label').text().trim()
      addStatusMessage($field, `Looking up ${name}...`, true, false)
      const values = getFieldValues($field);
      $.ajax({
        type: 'GET',
        url: endpoint,
        data: { crn: values },
        traditional: true, // Don't put stupid [] after the parameter keys
        dataType: 'json',
      }).done(function(data){
        if (data.is_error) {
          let error = data.message ? data.message : 'Unknown error'
          addStatusMessage($field, `Error looking up ${name}: ${error}`, false, true)
        } else {
          for (const [name, value] of Object.entries(data.result)) {
            var $f = $('.linkspace-field[data-name-short="'+name+'"]')
            setFieldValues($f, value)
          }
          removeStatusMessage($field)
        }
      })
      .fail(function(jqXHR, textStatus, textError) {
        // Use error in JSON from endpoint if available, otherwise HTTP status
        const err_message = (jqXHR.responseJSON && jqXHR.responseJSON.message) || jqXHR.statusText;
        const errorMessage = `Failed to look up ${name}: ${err_message}`
        addStatusMessage($field, errorMessage, false, true)
      });
    });
  }
}

const addStatusMessage = ($field, message, spinner, is_error) => {
  let $notice = $field.find('.lookup-status')
  let $text = $notice.find('.status-text')
  $text.text(message)
  if (is_error) {
    $text.addClass("text-danger")
    $text.removeClass("text-info")
  } else {
    $text.addClass("text-info")
    $text.removeClass("text-danger")
  }
  if (spinner) {
    $notice.find('.spinner-border').show()
  } else {
    $notice.find('.spinner-border').hide()
  }
  $notice.removeClass("d-none")
}

const removeStatusMessage = ($field) => {
  $field.find('.lookup-status').addClass("d-none")
}

export default ValueLookupComponent
