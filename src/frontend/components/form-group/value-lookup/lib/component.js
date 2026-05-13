import { Component } from 'component';
import { getFieldValues } from 'get-field-values';
import { setFieldValues } from 'set-field-values';

/**
 * Component to lookup a value at an external endpoint and prefill other fields from the response
 */
class ValueLookupComponent extends Component {
    /**
     * Create a new ValueLookupComponent
     * @param {HTMLElement} element The HTML element that this component is attached to
     */
    constructor(element) {
        super(element);
        this.initLookupComponent();
    }

    /**
     * Initializes the value lookup component by setting up the endpoint and fields
     */
    initLookupComponent() {
        const field = this.getLookupEndpoint();
        this.setupValueLookup(field);
    }

    /**
     * Get the lookup endpoint and fields from the component's data attributes
     * @returns {object} An object containing the field element, endpoint URL, and fields to lookup
     */
    getLookupEndpoint() {
        const lookup_endpoint = $(this.element).data('lookup-endpoint');
        const lookup_fields = $(this.element).data('lookup-fields');
        return {
            field: $(this.element),
            endpoint: lookup_endpoint,
            fields: lookup_fields
        };
    }

    /**
     * Set up the value lookup functionality
     * @param {object} field The field object containing the endpoint and fields to lookup
     */
    setupValueLookup(field) {
        const endpoint = field.endpoint;
        const $field = field.field;
        $field.on('change', function () {
            const all_fields = [];
            const data = {};
            let has_values = field.fields.every(function (name_short) {
                const $f = $('.linkspace-field[data-name-short="' + name_short + '"]');
                all_fields.push($f.data('name'));
                const values = getFieldValues($f);
                data[name_short] = values;
                return values.filter(function (value) { return value !== undefined; }).length ? true : false;
            });
            // If one of the values in this group is blank then do not perform lookup
            if (!has_values) return false;
            const formatter = new Intl.ListFormat('en-GB', { style: 'long', type: 'conjunction' });
            const all_names = formatter.format(all_fields);
            // Remove any existing status messages on the whole record
            $('.lookup-status').addClass('d-none');
            addStatusMessage($field, `Looking up ${all_names}...`, true, false);
            $.ajax({
                type: 'GET',
                url: endpoint,
                timeout: 10000,
                data: data,
                traditional: true, // Don't put stupid [] after the parameter keys
                dataType: 'json'
            }).done(function (data) {
                if (data.is_error || !data.result) {
                    let error = data.message ? data.message : 'Unknown error';
                    addStatusMessage($field, error, false, true);
                } else {
                    for (const [name, value] of Object.entries(data.result)) {
                        var $f = $('.linkspace-field[data-name-short="' + name + '"]');
                        if (!$f || $f.length == 0) continue;
                        setFieldValues($f, value);
                    }
                    removeStatusMessage($field);
                }
            })
                .fail(function (jqXHR, textStatus) {
                    // Use error in JSON from endpoint if available, otherwise try and
                    // interpret error response appropriately
                    const err_message = textStatus == 'timeout'
                        ? `Failed to look up ${all_names}: request timed out`
                        : textStatus == 'parsererror' // result not in JSON
                            ? `Failed to look up ${all_names}: unexpected response format from server`
                            : (jqXHR.responseJSON && jqXHR.responseJSON.message)
                                ? jqXHR.responseJSON.message
                                : `Failed to look up ${all_names}: ${jqXHR.statusText}`;
                    addStatusMessage($field, err_message, false, true);
                });
        });
    }
}

/**
 * Add a status message to the field
 * @param {JQuery<HTMLElement>} $field The field element to add the status message to
 * @param {string} message The message to display
 * @param {boolean} spinner The flag to show a spinner
 * @param {boolean} is_error Is the message an error message
 * @todo Why is this not a method of the component?
 */
const addStatusMessage = ($field, message, spinner, is_error) => {
    let $notice = $field.find('.lookup-status');
    let $text = $notice.find('.status-text');
    $text.text(message);
    if (is_error) {
        $text.addClass('text-danger');
        $text.removeClass('text-info');
    } else {
        $text.addClass('text-info');
        $text.removeClass('text-danger');
    }
    if (spinner) {
        $notice.find('.spinner-border').show();
    } else {
        $notice.find('.spinner-border').hide();
    }
    $notice.removeClass('d-none');
};

/**
 * Remove the status message from the field
 * @param {JQuery<HTMLElement>} $field The field element to remove the status message from
 */
const removeStatusMessage = ($field) => {
    $field.find('.lookup-status').addClass('d-none');
};

export default ValueLookupComponent;
