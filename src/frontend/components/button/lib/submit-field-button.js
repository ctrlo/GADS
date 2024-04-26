import { Component } from "component";

export default class SubmitFieldButtonComponent extends Component {
    constructor(element) {
        super(element);
        this.el = $(element);
        this.initSubmitField();
    }

    initSubmitField() {
        this.el.on('click', (ev) => {

            const $jstreeContainer = $('#field_type_tree');
            const $jstreeEl = $('#tree-config .tree-widget-container');
            const $calcCode = $('#calcfield_card_header');

            const $displayConditionsBuilderEl = $('#displayConditionsBuilder');
            const res = $displayConditionsBuilderEl.length && $displayConditionsBuilderEl.queryBuilder('getRules');
            const $displayConditionsField = $('#displayConditions');

            const $instanceIDField = $('#refers_to_instance_id');
            const $filterEl = $instanceIDField.length && $(`[data-builder-id='${$instanceIDField.val()}']`);

            const $permissionTable = $('#default_field_permissions_table');

            let bUpdateTree = false;
            let bUpdateFilter = false;
            let bUpdateDisplayConditions = false;

            const $showInEdit = $("#show_in_edit")
            if (($calcCode.length && $calcCode.is(':visible')) && !$showInEdit.val()) {
                if (!this.errored) {
                    const error = document.createElement("div");
                    error.classList.add("form-text", "form-text--error");
                    error.innerHTML = "Please select the calculation field visibility before submitting the form";
                    $showInEdit.closest(".form-group").append(error);
                    error.scrollIntoView();
                    this.errored = true;
                }
                ev.preventDefault();
            }

            if (($jstreeContainer.length && $jstreeContainer.is(':visible') && $jstreeEl.length) || (!$jstreeContainer.length && $jstreeEl.length)) {
                bUpdateTree = true;
            }

            if ($instanceIDField.length && !$instanceIDField.prop('disabled') && $filterEl.length) {
                bUpdateFilter = true;
            }

            if (res && $displayConditionsField.length) {
                bUpdateDisplayConditions = true;
            }

            if (bUpdateTree) {
                const v = $jstreeEl.jstree(true).get_json('#', { flat: false });
                const mytext = JSON.stringify(v);
                const data = $jstreeEl.data();

                $.ajax({
                    async: false,
                    type: 'POST',
                    url: this.getURL(data),
                    data: { data: mytext, csrf_token: data.csrfToken }
                }).done(() => {
                    // eslint-disable-next-line no-alert
                    alert('Tree has been updated')
                });
            }

            if (bUpdateFilter && window.UpdateFilter) {
                window.UpdateFilter($filterEl, ev);
            }

            if (bUpdateDisplayConditions) {
                $displayConditionsField.val(JSON.stringify(res, null, 2));
            }

            /* By default, if the permissions datatable is paginated, then the
             * permission checkboxes on other pages will not be submitted and will
             * therefore be cleared. This code gets all the inputs in the datatable
             * and appends them to the form manually */
            const $inputs = $permissionTable.DataTable().$('input,select,textarea');
            $inputs.hide(); // Stop them appearing to the user in a strange format
            const $form = $(ev.currentTarget).closest('form');
            $permissionTable.remove();
            $form.append($inputs);
        });
    }

    getURL(data) {
        const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi

        if (devEndpoint) {
            return devEndpoint
        } else {
            return `/${data.layoutIdentifier}/tree/${data.columnId}`
        }
    }
}