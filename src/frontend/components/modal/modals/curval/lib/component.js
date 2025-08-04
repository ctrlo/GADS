/* eslint-disable @typescript-eslint/no-this-alias */
import ModalComponent from '../../../lib/component';
import { setFieldValues } from 'set-field-values';
import { guid as Guid } from 'guid';
import { initializeRegisteredComponents } from 'component';
import { validateRadioGroup, validateCheckboxGroup } from 'validation';
import { fromJson } from 'util/common';
import StorageProvider from 'util/storageProvider';

class CurvalModalComponent extends ModalComponent {

    static get allowReinitialization() { return true; }

    constructor(element) {
        super(element);
        this.context = undefined; // Populated on modal show
        if (!this.wasInitialized) this.initCurvalModal();
    }

    // Initialize the modal
    initCurvalModal() {
        this.setupModal();
        this.setupSubmit();
    }

    // Set the value of a curval. In order to ensure consistent data, this
    // function opens a modal edit for each curval, makes the changes, and then
    // submits. It does this synchronously so that the modal is only processing
    // one curval value at a time
    setValue($target, rows) {
        const layout_id = $target.data('column-id');
        const $m = this.el;

        let index = 0;
        const self = this;
        autosaveLoadValue();
        // Submit a single value for processing, and then once completed call the
        // next one
        function autosaveLoadValue() {

            if (index >= rows.length) return; // Finished?

            const id = location.pathname.split('/').pop();
            const record_id = isNaN(parseInt(id)) ? 0 : parseInt(id);

            let current_id = rows[index].identifier;
            let values = rows[index].values;

            // New records will have a GUID rather than record ID
            let guid;
            if (!/^\d+$/.test(current_id)) {
                guid = current_id;
                current_id = null;
            }
            const instance_name = $target.data('curval-instance-name');
            // Load the modal and load each value into its fields
            $m.find('.modal-body').load(self.getURL(current_id, instance_name, layout_id), function () {
                initializeRegisteredComponents($m.get(0));
                $m.find('.linkspace-field').each(function () {
                    const $field = $(this);
                    const key = `linkspace-column-${$field.data('column-id')}-${$('body').data('layout-identifier')}-${record_id}`;
                    const vals = values[key];
                    if (vals) {
                        setFieldValues($field, vals);
                    }
                });
                let $form = $m.find('.curval-edit-form');
                $form.data('guid', guid);
                ++index;
                $form.trigger('submit', autosaveLoadValue);
            });
        }
    }

    async curvalModalValidationSucceeded(form, values) {
        const form_data = form.serialize();
        const modal_field_ids = form.data('modal-field-ids');
        const col_id = form.data('curval-id');
        let guid = form.data('guid');
        const $formGroup = $('div[data-column-id=' + col_id + ']');
        const valueSelector = $formGroup.data('value-selector');
        const self = this;
        const $field = $(`#curval_list_${col_id}`).closest('.linkspace-field');
        const current_id = form.data('current-id');

        const textValue = jQuery
            .map(modal_field_ids, function (element) {
                const value = values['field' + element];
                return $('<div />')
                    .text(value)
                    .html();
            })
            .join(', ');

        if (valueSelector === 'noshow') {

            // No strict requirement for alias here, but it is needed below, so for the sake of consistency
            const row_cells = $('<tr class="table-curval-item">', self.context);

            jQuery.map($field.data('modal-field-ids'), function (element) {
                let value = values['field' + element];
                value = $('<div />').text(value)
                    .html();
                row_cells.append(
                    $('<td class="curval-inner-text">').append(value)
                );
            });

            const col_id = $field.data('column-id');
            const instance_name = $field.data('curval-instance-name');
            const editButton = $(
                `<td>
          <button type="button" class="btn btn-small btn-link btn-js-curval-modal" data-toggle="modal" data-target="#curvalModal" data-layout-id="${col_id}"
                data-instance-name="${instance_name}" ${current_id ? `data-current-id="${current_id}"` : ''}>
            <span class="btn__title">Edit</span>
          </button>
          </td>`,
                this.context
            );

            const removeButton = $(
                `<td>
          <button type="button" class="btn btn-small btn-delete btn-js-curval-remove">
            <span class="btn__title">Remove</span>
          </button>
        </td>`,
                this.context
            );

            // We may have a guid (new value) but the row may already exist in the
            // underlying form. Reuse it if so, so that it matches any existing
            // guids in the autosave
            let is_new_row;
            if (!guid && !current_id) {
                guid = Guid();
                is_new_row = true;
            }
            const hidden_input = $('<input>').attr({
                type: 'hidden',
                name: 'field' + col_id,
                value: form_data,
                'data-guid': guid
            });
            row_cells.append(editButton.append(hidden_input)).append(removeButton);

            /* Activate remove button in new row */
            initializeRegisteredComponents(row_cells[0]);

            const hidden = $('input[data-guid="' + guid + '"]', $field).val(form_data);
            if (is_new_row || !hidden.length) {
                $field.find('tbody').prepend(row_cells);
                $field.find('.dataTables_empty').hide();
            } else if (guid) {
                hidden.closest('.table-curval-item').replaceWith(row_cells);
            } else {
                // Only current_id available, happens when reloading values from autosave
                const $btn = $field.find(`.btn-js-curval-modal[data-current-id="${current_id}"]`);
                $btn.closest('.table-curval-item').replaceWith(row_cells);
            }
        } else {
            const $widget = $formGroup.find('.select-widget').first();
            const multi = $widget.hasClass('multi');
            const required = $widget.hasClass('select-widget--required');
            const $current = $formGroup.find('.current');
            const $currentItems = $current.find('[data-list-item]');

            const $search = $current.find('.search');
            const $answersList = $formGroup.find('.available');

            if (!multi) {
                /* Deselect current selected value */
                $currentItems.attr('hidden', '');
                $answersList.find('li input').prop('checked', false);
            }

            guid ||= Guid();
            const id = `field${col_id}_${guid}`;
            const deleteButton = multi
                ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times</button>'
                : '';

            $search.before(
                `<li data-list-item="${id}" data-list-text="${textValue}" data-form-data="${form_data}" data-guid="${guid}"><span class="widget-value__value">${textValue}</span>${deleteButton}</li>`
            ).before(' '); // Ensure space between elements in widget

            const inputType = multi ? 'checkbox' : 'radio';
            const strRequired = required ?
                `required="required" aria-required="true" aria-errormessage="${$widget.attr('id')}-err"` :
                '';

            $answersList.append(`<li class="answer" role="option">
        <div class="control">
          <div class="${multi ? 'checkbox' : 'radio-group__option'}">
            <input ${strRequired} id="${id}" name="field${col_id}" type="${inputType}" value="${form_data}" class="${multi ? '' : 'radio-group__input'}" checked aria-labelledby="${id}_label">
            <label id="${id}_label" for="${id}" class="${multi ? '' : 'radio-group__label'}">
              <span>${textValue}</span>
            </label>
          </div>
        </div>
        <div class="details">
          <button type="button" class="btn btn-small btn-danger btn-js-curval-remove">
            <span class="btn__title">Remove</span>
          </button>
        </div>
      </li>`);

            this.updateWidgetState($widget, multi, required);

            /* Reinitialize widget */
            initializeRegisteredComponents($formGroup[0]);
            import(/* webpackChunkName: "select-widget" */ '../../../../form-group/select-widget/lib/component')
                .then(({ default: SelectWidgetComponent }) => {
                    new SelectWidgetComponent($widget[0]);
                });
        }

        // Update autosave values for all changes in this edit
        const id = location.pathname.split('/').pop();
        const record_id = isNaN(parseInt(id)) ? 0 : parseInt(id);
        const parent_key = `linkspace-column-${col_id}-${$('body').data('layout-identifier')}-${record_id}`;
        const storageProvider = new StorageProvider(`linkspace-record-change-${$('body').data('layout-identifier')}-${record_id}`);
        let existing = fromJson(await storageProvider.getItem(parent_key) ?? '[]');
        const identifier = current_id || guid;
        // "existing" is the existing values for this curval
        // Pull out the current record if it exists
        let existing_row = existing.filter((item) => item.identifier == identifier)[0] || { identifier: identifier };
        // And then remove it from the array so that we can re-add it in a moment
        existing = existing.filter((item) => Number.isInteger(item) || item.identifier != identifier);
        // Retrieve all the changes from the modal record form
        let changes = form.data('autosave-changes');
        // Changes will not exist if this update is being triggered by the restore of a previous autosave
        if (changes) {
            // Add them into the saved values for the single curval field
            existing_row.values ||= {};
            for (let [column_key, values] of Object.entries(changes)) {
                existing_row.values[column_key] = values;
            }
            existing.push(existing_row);
            // Store as array for consistency with other field types
            await storageProvider.setItem(parent_key, JSON.stringify(existing));
        }

        $(this.element).modal('hide');
        $formGroup.trigger('change', true);
    }

    updateWidgetState($widget, multi, required) {
        const $current = $widget.find('.current');
        const $visible = $current.children('[data-list-item]:not([hidden])');

        $current.toggleClass('empty', $visible.length === 0);

        if (required) {
            if (multi) {
                validateCheckboxGroup($widget);
            } else {
                validateRadioGroup($widget);
            }
        }
    }

    curvalModalValidationFailed(form, errorMessage) {
        form
            .find('.alert')
            .text(errorMessage)
            .removeAttr('hidden');
        form
            .parents('.modal-content')
            .get(0)
            .scrollIntoView();
        form.find('button[type=submit]').prop('disabled', false);
    }

    setupModal() {
        this.el.on('show.bs.modal', (ev) => {
            const button = ev.relatedTarget;
            const $field = $(button).closest('.linkspace-field');
            const layout_id = $field.data('column-id');
            const instance_name = $field.data('curval-instance-name');
            const current_id = $(button).data('current-id');
            const hidden = $(button)
                .closest('.table-curval-item')
                .find(`input[name=field${layout_id}]`);
            const form_data = hidden.val();
            const mode = hidden.length ? 'edit' : 'add';
            let guid;

            if ($field.find('.table-curval-group').length) {
                this.context = $field.find('.table-curval-group');
            } else if ($field.find('.select-widget').length) {
                this.context = $field.find('.select-widget');
            }

            // For edits, write a guid to the row now (if it hasn't already been
            // written), which will be matched on submission.
            // For new records, a guid is written on submission
            if (mode === 'edit') {
                guid = hidden.data('guid');
                if (!guid) {
                    guid = Guid();
                    hidden.attr('data-guid', guid);
                }
            }

            const $m = $(this.element);
            const self = this;
            $m.find('.modal-body').text('Loading...');

            $m.find('.modal-body').load(
                this.getURL(current_id, instance_name, layout_id, form_data),
                function () {
                    if (mode === 'edit') {
                        $m.find('form').data('guid', guid);
                    }
                    initializeRegisteredComponents(self.element);
                }
            );

            $m.on('focus', '.datepicker', function () {
                $(this).datepicker({
                    format: $m.attr('data-dateformat-datepicker'),
                    autoclose: true
                });
            });

            $m.off('hide.bs.modal')
                .on('hide.bs.modal', () => {
                    return confirm('Closing this dialogue will cancel any work. Are you sure you want to do so?');
                });
        });

    }

    getURL(current_id, instance_name, layout_id, form_data) {

        let url = current_id
            ? `/record/${current_id}`
            : `/${instance_name}/record/`;

        url = `${url}?include_draft&modal=${layout_id}`;
        if (form_data) url = url + `&${form_data}`;
        return url;
    }

    setupSubmit() {
        const self = this;

        $(this.element).on('submit', '.curval-edit-form', function (e, autosaveLoadValue) {
            // Don't show close warning when user clicks submit button
            self.el.off('hide.bs.modal');

            e.preventDefault();
            const $form = $(this);
            const form_data = $form.serialize();

            $form.addClass('edit-form--validating');
            $form.find('.alert').attr('hidden', '');

            const devData = window.siteConfig && window.siteConfig.curvalData;

            if (devData) {
                self.curvalModalValidationSucceeded($form, devData.values);
            } else {
                let url = $form.attr('action') + '?validate&include_draft&source=' + $form.data('curval-id');
                $.post(
                    url,
                    form_data,
                    function (data) {
                        const fieldId = $form.data('curval-id');
                        const $field = $('[data-column-type="curval"][data-column-id="' + fieldId + '"]');
                        if (data.error === 0) {
                            const e = $.Event('validationPassed');
                            $field.trigger(e);
                            self.curvalModalValidationSucceeded($form, data.values);
                        } else {
                            if (autosaveLoadValue) {
                                const e = $.Event('validationFailed', { message: data.message || 'Something went wrong!' });
                                $field.trigger(e);
                                // We still allow the form to submit as if it was correct
                                self.curvalModalValidationSucceeded($form, data.values);
                            } else {
                                const errorMessage =
                  data.error === 1 ? data.message : 'Oops! Something went wrong.';
                                self.curvalModalValidationFailed($form, errorMessage);
                            }
                        }
                    },
                    'json'
                )
                    .fail(function (jqXHR, textstatus, errorthrown) {
                        const errorMessage = `Oops! Something went wrong: ${textstatus}: ${errorthrown}`;
                        self.curvalModalValidationFailed($form, errorMessage);
                    })
                    .always(function () {
                        $form.removeClass('edit-form--validating');
                        if (autosaveLoadValue) autosaveLoadValue();
                    });
            }
        });
    }
}

export default CurvalModalComponent;
