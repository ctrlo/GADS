import { Component } from 'component';
import { setFieldValues } from "set-field-values";
import gadsStorage from 'util/gadsStorage';

class AutosaveModal extends Component {
  constructor(element) {
    super(element);
    this.table_key = `linkspace-record-change-${$('body').data('layout-identifier')}`;
    this.initAutosaveModal();
  }

  async initAutosaveModal() {
    const $modal = $(this.element);
    
    $modal.find('.btn-js-restore-values').on('click', function (e) {
      e.preventDefault();
      const $form = $('.form-edit');

      let $list = $("<ul></ul>");
      const $body = $modal.find(".modal-body");
      $body.html("<p>Restoring values...</p>").append($list);
      $form.find('.linkspace-field').each(async function(){
        const $field = $(this);
        const json = await gadsStorage.getItem(`linkspace-column-${$field.data('column-id')}`, 'local');
        if (json) {
          const values = JSON.parse(json);
          if (Array.isArray(values))
            setFieldValues($field, values);
            const name = $field.data("name");
            let $li = $(`<li>Restored ${name}</li>`);
            $list.append($li);
        }
      });
      $body.append("<p>All values restored.</p>");
      $modal.find(".modal-footer").find("button:not(.btn-cancel)").hide();
      $modal.find(".modal-footer").find(".btn-cancel").text("Close");
    });

    const item = await gadsStorage.getItem(this.table_key, 'local');
    console.log('item', item);

    if (item){
      $modal.modal('show');
      $modal.find('.btn-js-delete-values').attr('disabled', 'disabled').hide();
    }
  }

}

export default AutosaveModal;
