import { Component } from 'component';
import { setFieldValues } from "set-field-values";

class AutosaveModal extends Component {
  constructor(element) {
    super(element);
    this.table_key = `linkspace-record-change-${$('body').data('layout-identifier')}`;
    this.initAutosaveModal();
  }

  initAutosaveModal() {
    const $modal = $(this.element);

    $modal.find('.btn-js-restore-values').on('click', function (e) {
      e.preventDefault();
      const $form = $('.form-edit');

      let $list = $("<ul></ul>");
      const $body = $modal.find(".modal-body");
      $body.html("<p>Restoring values...</p>").append($list);
      $form.find('.linkspace-field').each(function(){
        const $field = $(this);
        const json = localStorage.getItem(`linkspace-column-${$field.data('column-id')}`);
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

    if (localStorage.getItem(this.table_key))
      $modal.modal('show');
  }

}

export default AutosaveModal;
