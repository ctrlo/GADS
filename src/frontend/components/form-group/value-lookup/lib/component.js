import { Component } from 'component'
import { getFieldValues } from "get-field-values"
import { setFieldValues } from "set-field-values"

/* Used to lookup a value at an external endpoint
 * and prefill other fields from the response */

class ValueLookupComponent extends Component {
  constructor(element) {
    super(element)
    this.initLookupComponent()
  }

  initLookupComponent() {
    const field = this.getLookupEndpoint();
    this.setupValueLookup(field);
  }

  getLookupEndpoint() {
    const lookup_endpoint = $(this.element).data("lookup-endpoint");
    const lookup_fields = $(this.element).data("lookup-fields");
    return {
      field: $(this.element),
      endpoint: lookup_endpoint,
      fields: lookup_fields
    };
  }

  setupValueLookup(field) {
    const endpoint = field.endpoint;
    const $field = field.field;
    $field.on("change", function () {
      const all_fields = []
      const data = {}
      let has_values = field.fields.every(function (name_short) {
        const $f = $('.linkspace-field[data-name-short="' + name_short + '"]')
        all_fields.push($f.data('name'))
        const values = getFieldValues($f)
        data[name_short] = values
        return values.filter(function (value) { return value !== undefined }).length ? true : false
      });
      // If one of the values in this group is blank then do not perform lookup
      if (!has_values) return false
      const formatter = new Intl.ListFormat('en-GB', { style: 'long', type: 'conjunction' })
      const all_names = formatter.format(all_fields)
      // Remove any existing status messages on the whole record
      $('.lookup-status').addClass("d-none")
      addStatusMessage($field, `Looking up ${all_names}...`, true, false)
      $.ajax({
        type: 'GET',
        url: endpoint,
        timeout: 10000,
        data: data,
        traditional: true, // Don't put stupid [] after the parameter keys
        dataType: 'json',
      }).done(function (data) {
        if (data.is_error || !data.result) {
          let error = data.message ? data.message : 'Unknown error'
          addStatusMessage($field, error, false, true)
        } else {
          for (const [name, value] of Object.entries(data.result)) {
            var $f = $('.linkspace-field[data-name-short="' + name + '"]')
            if (!$f || $f.length == 0) continue;
            setFieldValues($f, value)
          }
          removeStatusMessage($field)
        }
      })
        .fail(function (jqXHR, textStatus) {
          // Use error in JSON from endpoint if available, otherwise try and
          // interpret error response appropriately
          const err_message = textStatus == "timeout"
            ? `Failed to look up ${all_names}: request timed out`
            : textStatus == "parsererror" // result not in JSON
              ? `Failed to look up ${all_names}: unexpected response format from server`
              : (jqXHR.responseJSON && jqXHR.responseJSON.message)
                ? jqXHR.responseJSON.message
                : `Failed to look up ${all_names}: ${jqXHR.statusText}`
          addStatusMessage($field, err_message, false, true)
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
