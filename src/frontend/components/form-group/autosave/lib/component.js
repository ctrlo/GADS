import { getFieldValues } from "get-field-values";
import AutosaveBase from './autosaveBase';

class AutosaveComponent extends AutosaveBase {
  async initAutosave() {
    const $field = $(this.element);
    const self = this;
    if ($field.data('is-readonly')) return;

    // For each field, when it changes save the value to the local storage
    $field.on('change', async function () {
      const recovering = await self.storage.getItem('recovering');
      if(recovering) return;
      if ($field.hasClass('field--changed')) $field.removeClass('field--changed');
      let values = getFieldValues($field, false, false, true);
      values = (Array.isArray(values) ? values : [values]).filter(function (element) {
        return !!element;
      });

      const column_key = self.columnKey($field);

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
        if ($field.data('show-add') && await self.storage.getItem(column_key)) {
          // Get all existing values for this curval
          let existing = JSON.parse(await self.storage.getItem(column_key));
          // Map them into an index
          let indexed = existing.filter((item) => !Number.isInteger(item)).reduce((a, v) => ({ ...a, [v.identifier]: v }), {});
          // For each value, if it's not an ID then get the full set of values
          // that were previously retrieved from local storage
          values = values.map((item) => Number.isInteger(item) ? item : indexed[item]);
        }
        await self.storage.setItem(column_key, JSON.stringify(values));
        if(!(await self.storage.getItem(self.table_key))) await self.storage.setItem(self.table_key, true);
      } else {
        // Delete any values now deleted
        let existing = await self.storage.getItem(column_key) ? JSON.parse(await self.storage.getItem(column_key)) : [];
        existing = existing.filter((item) => values.includes(item.identifier));
        await self.storage.setItem(column_key, JSON.stringify(existing));
        // And flag that something has changed (even if nothing has been
        // deleted, this will need setting if the change was triggered as a
        // result of a modal submit for a curval add - everything else will
        // have already been saved)
        if(!(await self.storage.getItem(self.table_key))) await self.storage.setItem(self.table_key, true);
      }
    });
  }
}

export default AutosaveComponent;
