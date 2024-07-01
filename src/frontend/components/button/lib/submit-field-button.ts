import "jstree";
import "datatables.net";
import "@lol768/jquery-querybuilder-no-eval";

// TODO: This probably need refactoring

/**
 * This class is responsible for handling the submit button on the field
 */
export default class SubmitFieldButton {
    private errored: boolean = false;

    /**
     * Create a submit field button
     * @param element The submit button element
     */
    constructor(element:JQuery<HTMLElement>) {
        element.on("click", (ev) => {

            const $jstreeContainer = $("#field_type_tree");
            const $jstreeEl = $("#tree-config .tree-widget-container");
            const $calcCode = $("#calcfield_card_header");

            const $displayConditionsBuilderEl = $("#displayConditionsBuilder");
            //Bit of typecasting here, purely because the queryBuilder plugin doesn't have types
            const res = $displayConditionsBuilderEl.length && (<any>$displayConditionsBuilderEl).queryBuilder("getRules");
            const $displayConditionsField = $("#displayConditions");

            const $instanceIDField = $("#refers_to_instance_id");
            const $filterEl = $instanceIDField.length && $(`[data-builder-id='${$instanceIDField.val()}']`);

            const $permissionTable = $("#default_field_permissions_table");

            let bUpdateTree = false;
            let bUpdateFilter = false;
            let bUpdateDisplayConditions = false;

            const $showInEdit = $("#show_in_edit");
            if (($calcCode.length && $calcCode.is(":visible")) && !$showInEdit.val()) {
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

            if (($jstreeContainer.length && $jstreeContainer.is(":visible") && $jstreeEl.length) || (!$jstreeContainer.length && $jstreeEl.length)) {
                bUpdateTree = true;
            }

            if ($instanceIDField.length && !$instanceIDField.prop("disabled") && $filterEl.length) {
                bUpdateFilter = true;
            }

            if (res && $displayConditionsField.length) {
                bUpdateDisplayConditions = true;
            }

            if (bUpdateTree) {
                //Bit of typecasting here, purely because the jstree plugin doesn't have types
                const v = (<any>$jstreeEl).jstree(true).get_json("#", {flat: false});
                const mytext = JSON.stringify(v);
                const data = $jstreeEl.data();

                $.ajax({
                    async: false,
                    type: "POST",
                    url: this.getURL(data),
                    data: {data: mytext, csrf_token: data.csrfToken}
                }).done(() => {
                    // eslint-disable-next-line no-alert
                    alert("Tree has been updated");
                });
            }

            // @ts-expect-error - This is a global function
            if (bUpdateFilter && window.UpdateFilter) {
                // @ts-expect-error - This is a global function
                window.UpdateFilter($filterEl, ev);
            }

            if (bUpdateDisplayConditions) {
                $displayConditionsField.val(JSON.stringify(res, null, 2));
            }

            /* By default, if the permissions datatable is paginated, then the
             * permission checkboxes on other pages will not be submitted and will
             * therefore be cleared. This code gets all the inputs in the datatable
             * and appends them to the form manually */
            const $inputs = $permissionTable.DataTable().$("input,select,textarea");
            $inputs.hide(); // Stop them appearing to the user in a strange format
            const $form = $(ev.currentTarget).closest("form");
            $permissionTable.remove();
            $form.append($inputs);
        });
    }

    /**
     * Get the URL for the tree API
     * @param data The data for the tree
     * @returns The URL for the tree API
     */
    private getURL(data:JQuery.PlainObject):string {
        if (window.test) return "";

        const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi;

        return devEndpoint ? devEndpoint : `/${data.layoutIdentifier}/tree/${data.columnId}`;
    }
}
