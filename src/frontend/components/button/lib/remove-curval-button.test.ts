import "testing/globals.definitions";
import createRemoveCurvalButton from "./remove-curval-button";
import {describe, jest, it, expect} from "@jest/globals";

describe("createRemoveCurvalButton", () => {
    const dropdown = `
<div class="form-group linkspace-field" data-column-id="77" data-column-type="curval" data-value-selector="dropdown"
    data-name="Curval" data-name-short="" data-is-multivalue="true" data-dependent-not-shown="0"
    style="margin-left:0px">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="77-label">Curval</legend>
        </div>
        <div class="select-widget select-widget--required multi" data-value-selector="dropdown" data-layout-id="table7"
            data-typeahead-id="77" data-field="field77" data-details-modal="#detailsModal">
            <div class="select-widget-dropdown">
                <div class="form-control">
                    <ul class="current empty">
                        <li class="none-selected">Select option(s)</li>
                        <li data-list-item="field77_0936c3be-2583-73e2-26a1-b0205f7f507a" hidden="hidden">
                            <span class="widget-value__value">bfid, 586, Roberts, Dave, Roberts, Dave</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                    </ul>
                </div>
                <ul class="available select__menu dropdown-menu show with-details" id="77-values-multi"
                    aria-labelledby="77-label" role="listbox" hidden="hidden">
                    <li class="spinner" hidden="hidden">
                        <div class="spinner-border" role="status">
                            <span class="sr-only">Loading...</span>
                        </div>
                    </li>
                    <li class="has-noresults" hidden="">No results</li>
                    <li class="answer" role="option">
                        <div class="control">
                            <div class="checkbox">
                                <input required="required" aria-required="true" aria-errormessage="undefined-err"
                                    id="field77_0936c3be-2583-73e2-26a1-b0205f7f507a" name="field77" type="checkbox"
                                    value="csrf_token=TkeADPnSrnZ8ONkzpGAzi4J8aLkgjN4S&amp;field67=bfid&amp;field68=586&amp;field79=&amp;field79=1&amp;submit=1"
                                    class="" checked=""
                                    aria-labelledby="field77_0936c3be-2583-73e2-26a1-b0205f7f507a_label">
                                <label id="field77_0936c3be-2583-73e2-26a1-b0205f7f507a_label"
                                    for="field77_0936c3be-2583-73e2-26a1-b0205f7f507a" class="">
                                    <span>bfid, 586, Roberts, Dave, Roberts, Dave</span>
                                </label>
                            </div>
                        </div>
                        <div class="details">
                            <button type="button" class="btn btn-small btn-danger btn-js-curval-remove">
                                <span class="btn__title">Remove</span>
                            </button>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
    </fieldset>
    <button type="button" class="btn btn-js-curval-modal btn-add-link" data-toggle="modal" data-target="#curvalModal"
        data-layout-id="77" data-instance-name="table6">
        <span class="btn__title">Add</span>
    </button>
</div>
    `;

    const table = `
<div class="form-group linkspace-field" data-column-id="77" data-column-type="curval" data-value-selector="noshow"
    data-name="Curval" data-name-short="" data-is-multivalue="true" data-dependent-not-shown="0"
    style="margin-left:0px">
    <fieldset class="fieldset input">
        <div class="fieldset__legend">
            <legend id="77-label">Curval</legend>
        </div>
        <button type="button" class="btn btn-js-curval-modal btn-add-link" data-toggle="modal"
            data-target="#curvalModal" data-layout-id="77" data-instance-name="table6">
            <span class="btn__title">Add</span>
        </button>
        <div id="curval_list_77_wrapper" class="dt-container dt-bootstrap4 dt-empty-footer">
            <table class="data-table table table-curval-group table-thead-hidden table-striped dataTable dtr-column"
                id="curval_list_77" width="100%">
                <colgroup>
                    <col data-dt-column="0">
                    <col data-dt-column="1">
                </colgroup>
                <caption class="sr-only">Table to show values in Curval</caption>
                <thead>
                    <tr role="row">
                        <th data-dt-column="0" class="min-tablet-l data-table__header--invisible dt-orderable-none"
                            rowspan="1" colspan="1" aria-label="Edit">
                            <span class="dt-column-title">
                                <span>Edit</span>
                            </span>
                        </th>
                        <th data-dt-column="1" class="min-tablet-l data-table__header--invisible dt-orderable-none"
                            rowspan="1" colspan="1" aria-label="Remove">
                            <span class="dt-column-title">
                                <span>Remove</span>
                            </span>
                        </th>
                        <th data-dt-column="2"
                            class="dtr-control data-table__header--invisible dt-orderable-none dtr-hidden" rowspan="1"
                            colspan="1" aria-label="Toggle child row" style="display: none;">
                            <span class="dt-column-title">
                                <span>Toggle child row</span>
                            </span>
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <tr class="table-curval-item">
                        <td class="curval-inner-text">reg</td>
                        <td class="curval-inner-text">342</td>
                        <td class="curval-inner-text">Bobson, Bob</td>
                        <td class="curval-inner-text">Bobson, Bob</td>
                        <td>
                            <button type="button" class="btn btn-small btn-link btn-js-curval-modal" data-toggle="modal"
                                data-target="#curvalModal" data-layout-id="77" data-instance-name="table6"
                                data-current-id="">
                                <span class="btn__title">Edit</span>
                            </button>
                            <input type="hidden" name="field77"
                                value="csrf_token=gberiaerbg&amp;field67=reg&amp;field68=342&amp;field79=&amp;field79=1&amp;submit=1">
                        </td>
                        <td>
                            <button type="button" class="btn btn-small btn-delete btn-js-curval-remove">
                                <span class="btn__title">Remove</span>
                            </button>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                </tfoot>
            </table>
        </div>
        <input type="hidden" name="field77" value="" data-restore-value="">
    </fieldset>
</div>
    `;

    it("should remove the answer on a dropdown", () => {
        const dom = $(dropdown);
        const $btn = dom.find(".btn-js-curval-remove");
        let $values = dom.find(".answer");
        expect($values.length).toBe(1);
        expect($btn.length).toBe(1);
        createRemoveCurvalButton($btn);
        $btn.trigger("click");
        $values = dom.find(".answer");
        expect($values.length).toBe(0);
    });

    it("should remove the answer on a table", () => {
        window.confirm = jest.fn(() => true);
        const dom = $(table);
        const $btn = dom.find(".btn-js-curval-remove");
        let $values = dom.find(".table-curval-item");
        expect($values.length).toBe(1);
        expect($btn.length).toBe(1);
        createRemoveCurvalButton($btn);
        $btn.trigger("click");
        $values = dom.find(".table-curval-item");
        expect($values.length).toBe(0);
    });
});
