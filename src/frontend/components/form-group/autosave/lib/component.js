import { Component } from 'component';
import { getFieldValues } from "get-field-values";
import gadsStorage from 'util/gadsStorage';
class AutosaveComponent extends Component {
  constructor(element) {
    super(element);
    this.table_key = `linkspace-record-change-${$('body').data('layout-identifier')}`;
    this.initAutosaveFields();
  }

  initAutosaveFields() {
    const $field = $(this.element);
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    const self = this;
    if ($field.data('is-readonly')) return;

    // For each field, when it changes save the value to the local storage
    $field.on('change', async function () {
      let values = getFieldValues($field, false, false, true)
        .filter(function (element) {
          return !!element;
        });

      const column_key = `linkspace-column-${$field.data('column-id')}`;

      const $form = $field.closest('form');
      if ($form.hasClass('curval-edit-form')) {
        // For curval modals, don't write anything immediately in case user
        // cancels the modal. Store in form data in the modal and then save
        // locally on submit
        let existing = $form.data('autosave-changes') || {};
        existing[column_key] = values;
        $form.data('autosave-changes', existing);
      } else if ($field.data('value-selector') != 'noshow') {
        // If this field is a curval with an add button, then make sure that
        // any values that have been added (and will already be in storage)
        // are retained. These will be returned from getFieldValues() as guids,
        // but we need to retain all the associated values
        if ($field.data('show-add') && await gadsStorage.getItem(column_key)) {
          // Get all existing values for this curval
          let existing = JSON.parse(await gadsStorage.getItem(column_key));
          // Map them into an index
          let indexed = existing.filter((item) => !Number.isInteger(item)).reduce((a, v) => ({ ...a, [v.identifier]: v }), {});
          // For each value, if it's not an ID then get the full set of values
          // that were previously retrieved from local storage
          values = values.map((item) => Number.isInteger(item) ? item : indexed[item]);
        }
        await gadsStorage.setItem(column_key, JSON.stringify(values), "local");
        await gadsStorage.setItem(self.table_key, true, "local");
      } else {
        // Delete any values now deleted
        let existing = await gadsStorage.getItem(column_key, 'local') ? JSON.parse(await gadsStorage.getItem(column_key, 'local')) : [];
        existing = existing.filter((item) => values.includes(item.identifier));
        await gadsStorage.setItem(column_key, JSON.stringify(existing), "local");
        // And flag that something has changed (even if nothing has been
        // deleted, this will need setting if the change was triggered as a
        // result of a modal submit for a curval add - everything else will
        // have already been saved)
        await gadsStorage.setItem(self.table_key, true, "local");
      }
    });
  }
}

export default AutosaveComponent;
