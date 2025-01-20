import { setFieldValues } from "set-field-values";
import AutosaveBase from './autosaveBase';

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
      this.storage.setItem('recovering', true);
      let curvalCount = $form.find('.linkspace-field[data-column-type="curval"]').length;
      
      e.preventDefault();

      let errored = false;

      let $list = $("<ul></ul>");
      const $body = $modal.find(".modal-body");
      $body.html("<p>Restoring values...</p>").append($list);
      await Promise.all($form.find('.linkspace-field').map(async (_,field) => {
        const $field = $(field);
        await this.storage.getItem(this.columnKey($field)).then(json => {
          let values = json ? JSON.parse(json) : undefined;
          return values && Array.isArray(values) ? values : undefined;
        }).then(values => {
          const $editButton = $field.closest('.card--topic').find('.btn-js-edit');
          if ($editButton && $editButton.length) $editButton.trigger('click');
          if (Array.isArray(values)) {
            const name = $field.data("name");
            const type = $field.data("column-type");
            if (type === "curval") {
              $field.off("validationFailed");
              $field.off("validationPassed");
              $field.on("validationFailed", (e) => {
                curvalCount--;
                const $li = $(`<li class="li-error">Error restoring ${name}, please check these values before submission<ul><li class="warning">${e.message}</li></ul></li>`);
                $list.append($li);
                if(!curvalCount) this.storage.removeItem('recovering');
              });
              $field.on("validationPassed", () => {
                curvalCount--;
                const $li = $(`<li class="li-success">Restored ${name}</li>`);
                $list.append($li);
                if(!curvalCount) this.storage.removeItem('recovering');
              });
            }
            setFieldValues($field, values);
            if(type !== "curval") {
              const $li = $(`<li class="li-success">Restored ${name}</li>`);
              $list.append($li);
            }
            $field.addClass("field--changed");
          }
        }).catch(e => {
          const name = $field.data("name");
          const $li = $(`<li class="li-error">Failed to restore ${name}<ul><li class="warning">${e.message}</li></ul></li>`);
          console.error(e);
          $list.append($li);
          errored = true;
        });
      })).then(() => {
        $body.append(`<p>${errored ? "Values restored with errors." : "All values restored."} Please check that all field values are as expected.</p>`);
      }).catch(e => {
        $body.append(`<div class="alert alert-danger"><h4>Critical error restoring values</h4><p>${e}</p></div>`);
      }).finally(() => {
        $modal.find(".modal-footer").find("button:not(.btn-cancel)").hide();
        $modal.find(".modal-footer").find(".btn-cancel").text("Close");
        if(!curvalCount) this.storage.removeItem('recovering');
      });
    });

    const item = await this.storage.getItem(this.table_key);

    if (item){
      $modal.modal('show');
      $modal.find('.btn-js-delete-values').attr('disabled', 'disabled').hide();
    }
  }

}

export default AutosaveModal;
