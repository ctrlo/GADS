import { setFieldValues } from "set-field-values";
import AutosaveBase from './autosaveBase';

class AutosaveModal extends AutosaveBase {
  async initAutosave() {
    const $modal = $(this.element);
    const self = this;
    const $form = $('.form-edit');
    
    $modal.find('.btn-js-restore-values').on('click', async function (e) {
      e.preventDefault();

      let $list = $("<ul></ul>");
      const $body = $modal.find(".modal-body");
      $body.html("<p>Restoring values...</p>").append($list);
      await Promise.all($form.find('.linkspace-field').map(async function () {
        const $field = $(this);
        await self.storage.getItem(self.columnKey($field)).then(json => {
          let values = json ? JSON.parse(json) : undefined;
          return values && Array.isArray(values) && values.length ? values : undefined;
        }).then(values => {
          const $editButton = $field.closest('.card--topic').find('.btn-js-edit');
          if ($editButton && $editButton.length) $editButton.trigger('click');
          if (Array.isArray(values) && values.length) {
            setFieldValues($field, values);
            $field.addClass("field--changed");
            const name = $field.data("name");
            let $li = $(`<li class="li-success">Restored ${name}</li>`);
            $list.append($li);
          }
        }).catch(e => {
          const name = $field.data("name");
          let $li = $(`<li class="li-error">Failed to restore ${name}</li>`);
          console.error(e);
          $list.append($li);
        });
      })).then(() => {
        $body.append("<p>All values restored.</p>");
      }).catch(e => {
        $body.append(`<div class="alert alert-danger"><h4>Critical error restoring values</h4><p>${e}</p></div>`);
      }).finally(() => {
        $modal.find(".modal-footer").find("button:not(.btn-cancel)").hide();
        $modal.find(".modal-footer").find(".btn-cancel").text("Close");
      });
    });

    const item = (await Promise.all($form.find('.linkspace-field').map(async (_,field)=> {
      if(await self.storage.getItem(self.columnKey($(field)))) {
        return true;
      }
      return false;
    }))).includes(true)

    if (item){
      $modal.modal('show');
      $modal.find('.btn-js-delete-values').attr('disabled', 'disabled').hide();
    }
  }

}

export default AutosaveModal;
