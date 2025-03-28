import { setFieldValues } from "set-field-values";
import AutosaveBase from './autosaveBase';
import { fromJson } from "util/common";

/**
 * A modal that allows the user to restore autosaved values.
 */
class AutosaveModal extends AutosaveBase {
  /**
   * @inheritdoc
   */
  async initAutosave() {
    const $modal = $(this.element);
    const $form = $('.form-edit');

    $modal.find('.btn-js-restore-values').on('click', async (e) => {
      e.preventDefault();
      e.stopPropagation();

      // Hide all the buttons (we don't want any interaction to close the modal or the restore process fails)
      $modal.find(".modal-footer").find("button").hide();

      // This need awaiting or it returns before the value is fully set meaning if the recovery is "fast" it will not clear
      await this.storage.setItem('recovering', true);
      // Count the curvals so we don't return too early
      let curvalCount = 0;
      // Only count changed curvals - as each in the array has it's own event, we count the number of changes, not the number of fields
      await Promise.all($form.find('.linkspace-field[data-column-type="curval"]').map(async (_, field) => {
        await this.storage.getItem(this.columnKey($(field))) && (curvalCount += fromJson(await this.storage.getItem(this.columnKey($(field)))).length);
      }));

      let errored = false;

      let $list = $("<ul></ul>");
      const $body = $modal.find(".modal-body");
      $body.html("<p>Restoring values...</p><p><strong>Please be aware that linked records may take a moment to finish restoring.<strong><p>").append($list);
      // Convert the fields to promise functions (using the fields) that are run in parallel
      // This is only done because various parts of the codebase use the fields in different ways dependent on types (i.e. curval)
      Promise.all($form.find('.linkspace-field').map(async (_, field) => {
        const $field = $(field);
        // This was originally a bunch of promises, but as the code is async, we can await things here
        try {
          const json = await this.storage.getItem(this.columnKey($field))
          let values = json ? JSON.parse(json) : undefined;
          // If the value can't be parsed, ignore it
          if (!values) return;
          // If we are in view mode and we need to switch to edit mode, do that
          const $editButton = $field.closest('.card--topic').find('.btn-js-edit');
          if ($editButton && $editButton.length) $editButton.trigger('click');
          if (Array.isArray(values)) {
            const name = $field.data("name");
            const type = $field.data("column-type");
            if (type === "curval") {
              // Curvals need to work event-driven - this is because the modal doesn't always load fully,
              // meaning the setvalue doesn't work correctly for dropdowns (mainly)
              $field.off("validationFailed");
              $field.off("validationPassed");
              $field.on("validationFailed", (e) => {
                // Decrement the curval count
                curvalCount--;
                const $li = $(`<li class="li-error">Error restoring ${name}, please check these values before submission<ul><li class="warning">${e.message}</li></ul></li>`);
                $list.append($li);
                // If we've done all fields, turn off the recovery flag
                if (!curvalCount) {
                  // Hide the restore button and show the close button
                  $modal.find(".modal-footer").find(".btn-cancel").text("Close").show();
                  this.storage.removeItem('recovering');
                }
              });
              $field.on("validationPassed", () => {
                // Decrement the curval count
                curvalCount--;
                const $li = $(`<li class="li-success">Restored ${name}</li>`);
                $list.append($li);
                // If we've done all fields, turn off the recovery flag
                if (!curvalCount) {
                  // Hide the restore button and show the close button
                  $modal.find(".modal-footer").find(".btn-cancel").text("Close").show();
                  this.storage.removeItem('recovering');
                }
              });
            }
            try {
              setFieldValues($field, values);
            } catch (e) {
              console.error(e);
            }
            if (type !== "curval") {
              const $li = $(`<li class="li-success">Restored ${name}</li>`);
              $list.append($li);
            }
            $field.addClass("field--changed");
          }
        } catch (e) {
          // Catch anything within the mapped promises
          const name = $field.data("name");
          const $li = $(`<li class="li-error">Failed to restore ${name}<ul><li class="warning">${e.message}</li></ul></li>`);
          console.error(e);
          $list.append($li);
          errored = true;
        }
      })).then(() => {
        // If there are errors, show an appropriate message, otherwise show a success message
        $body.append(`<p>${errored ? "Values restored with errors." : "All values restored."} Please check that all field values are as expected.</p>`);
      }).catch(e => {
        // If there are any errors that can't be handled in the mapped promises, show a critical error message
        $body.append(`<div class="alert alert-danger"><h4>Critical error restoring values</h4><p>${e}</p></div>`);
      }).finally(() => {
        // Only allow to close once recovery is finished
        if(!curvalCount || errored) {
          // Show the close button
          $modal.find(".modal-footer").find(".btn-cancel").text("Close").show();
          this.storage.removeItem('recovering');
        }
      });
    });

    // Do we need to run an autorecover?
    const item = await this.storage.getItem(this.table_key);

    if (item) {
      $modal.modal('show');
      $modal.find('.btn-js-delete-values').attr('disabled', 'disabled').hide();
    }
  }
}

export default AutosaveModal;
