import { setFieldValues } from "set-field-values";
import AutosaveBase from './autosaveBase';

class AutosaveModal extends AutosaveBase {
  async initAutosave() {
    const $modal = $(this.element);
    const self = this;
    
    $modal.find('.btn-js-restore-values').on('click', function (e) {
      e.preventDefault();
      const $form = $('.form-edit');

      let $list = $("<ul></ul>");
      const $body = $modal.find(".modal-body");
      $body.html("<p>Restoring values...</p>").append($list);
      $form.find('.linkspace-field').each(async function(){
        const $field = $(this);
        const json = await self.storage.getItem(self.columnKey($field));
        if (json) {
          const values = JSON.parse(json);
          const $editButton = $field.closest('.card--topic').find('.btn-js-edit');
          if($editButton && $editButton.length) $editButton.trigger('click');
          if (Array.isArray(values))
            console.log('values', values);
            setFieldValues($field, values);
            $field.addClass("field--changed");
            const name = $field.data("name");
            let $li = $(`<li>Restored ${name}</li>`);
            $list.append($li);
        }
      });
      $body.append("<p>All values restored.</p>");
      $modal.find(".modal-footer").find("button:not(.btn-cancel)").hide();
      $modal.find(".modal-footer").find(".btn-cancel").text("Close");
    });

    const item = await self.storage.getItem(this.table_key);
    console.log('item', item);

    if (item){
      $modal.modal('show');
      $modal.find('.btn-js-delete-values').attr('disabled', 'disabled').hide();
    }
  }

}

export default AutosaveModal;
