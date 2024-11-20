import inputComponent from "../../components/form-group/input";
import buttonComponent from "../../components/button";
import multipleSelectComponent from "../../components/form-group/multiple-select";
import selectWidgetComponent from "../../components/form-group/select-widget";
import { describe, it, expect } from '@jest/globals';
import { setFieldValues } from "./set-field-values";
import "../../testing/globals.definitions";
import "components/button/lib/rename-button";

declare global {
    interface JQuery<TElement = HTMLElement> {
        renameButton: (options?: any) => JQuery<TElement>;
        filedrag: (options?: any) => JQuery<TElement>;
    }
}

if(typeof jQuery !== 'undefined') {
    (($)=>{
        $.fn.renameButton = jest.fn().mockReturnThis();
        $.fn.filedrag = jest.fn().mockReturnThis();
    })(jQuery);
}

const stringDom = `
<div class="form-group linkspace-field" data-column-id="19" data-column-type="string" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="text" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px" data-component-initialized-autosavecomponent="true">
    <div class="input input--required invalid">
        <div class="input__label">
            <label for="19">text</label>
        </div>
        <div class="input__field">
            <input type="text" class="form-control " id="19" name="field19" placeholder="" value=""
                data-restore-value="" required="" aria-required="true" aria-invalid="true">
        </div>
    </div>
</div>
    `;

const multiStringDom = `
<div class="form-group linkspace-field" data-column-id="19" data-column-type="string" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="text" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px">
    <div class="">
        <fieldset class="fieldset fieldset--required">
            <div class="fieldset__legend">
                <legend id="19-label">text</legend>
            </div>
            <div class="multiple-select">
                <div class="multiple-select__list">
                    <div class="multiple-select__row">
                        <div class="input  input--required">
                            <div class="input__field">
                                <input type="text" class="form-control " id="19" name="field19" placeholder="" value=""
                                    data-restore-value="" required="" aria-required="true">
                            </div>
                        </div>
                        <button type="button" class="btn btn-delete btn-delete--hidden">
                            <span class="btn__title">Delete</span>
                        </button>
                    </div>
                </div>
                <button type="button" class="btn btn-add-link">
                    <span class="btn__title">Add extra value</span>
                </button>
            </div>
        </fieldset>
    </div>
</div>
    `;

const enumField = `
<div class="form-group linkspace-field" data-column-id="20" data-column-type="enum" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="enum" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <input type="hidden" name="field20" value="">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="20-label">enum</legend>
        </div>
        <div class="select-widget select-widget--required">
            <div class="select-widget-dropdown">
                <div class="form-control">
                    <ul class="current empty">
                        <li class="none-selected">Select option</li>
                        <li data-list-id="6" data-list-item="20_6" data-list-text="Yes" hidden="">
                            <span class="widget-value__value">Yes</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                        <li class="search">
                            <input type="search" class="form-control-search" style="width:100px" placeholder="Search..."
                                aria-controls="20-values-single" aria-expanded="false" aria-describedby="20-label">
                        </li>
                    </ul>
                </div>
                <ul hidden="" class="available select__menu dropdown-menu show " id="20-values-single"
                    aria-labelledby="20-label" role="listbox">
                    <li class="has-noresults" hidden="">No results</li>
                    <li class="answer" role="option">
                        <div class="radio-group__option">
                            <input type="radio" id="20_6" class="radio-group__input" name="field20" value="6"
                                required="" aria-required="true" data-value="Yes">
                            <label class="radio-group__label" for="20_6">Yes</label>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
    </fieldset>
</div>
    `;

const multiEnumField = `
<div class="form-group linkspace-field" data-column-id="20" data-column-type="enum" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="enum" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px">
    <fieldset class="fieldset input fieldset--required fieldset--invalid">
        <div class="fieldset__legend">
            <legend id="20-label">enum</legend>
        </div>
        <div class="select-widget select-widget--required multi invalid">
            <div class="select-widget-dropdown">
                <div class="form-control">
                    <ul class="current empty">
                        <li class="none-selected">Select option(s)</li>
                        <li data-list-id="6" data-list-item="20_6" data-list-text="Yes" hidden="">
                            <span class="widget-value__value">Yes</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                        <li data-list-id="7" data-list-item="20_7" data-list-text="No" hidden="">
                            <span class="widget-value__value">No</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                        <li class="search">
                            <input type="search" class="form-control-search" style="width:100px" placeholder="Search..."
                                aria-controls="20-values-multi" aria-expanded="false" aria-describedby="20-label">
                        </li>
                    </ul>
                </div>
                <ul class="available select__menu dropdown-menu show" id="20-values-multi" aria-labelledby="20-label"
                    role="listbox" hidden="hidden">
                    <li class="has-noresults" hidden="">No results</li>
                    <li class="answer" role="option">
                        <div class="checkbox ">
                            <input id="20_6" type="checkbox" name="field20" value="6" class=""
                                aria-labelledby="20_6-label" data-value="Yes">
                            <label for="20_6" id="20_6-label" class="checkbox-label">Yes</label>
                        </div>
                    </li>
                    <li class="answer" role="option">
                        <div class="checkbox ">
                            <input id="20_7" type="checkbox" name="field20" value="7" class=""
                                aria-labelledby="20_7-label" data-value="No">
                            <label for="20_7" id="20_7-label" class="checkbox-label">No</label>
                        </div>
                    </li>
                </ul>
            </div>
            <div class="error">
                <span id="-err" class="form-text form-text--error" aria-live="off">enum is a required field.</span>
            </div>
        </div>
    </fieldset>
</div>
`;

const personField = `
<div class="form-group linkspace-field" data-column-id="21" data-column-type="person" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Person" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <input type="hidden" name="field21" value="">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="21-label">Person</legend>
        </div>
        <div class="select-widget select-widget--required">
            <div class="select-widget-dropdown">
                <div class="form-control">
                    <ul class="current empty">
                        <li class="none-selected">Select option</li>
                        <li data-list-id="1" data-list-item="21_1" data-list-text="Roberts, Dave" hidden="">
                            <span class="widget-value__value">Roberts, Dave</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                        <li class="search">
                            <input type="search" class="form-control-search" style="width:100px" placeholder="Search..."
                                aria-controls="21-values-single" aria-expanded="false" aria-describedby="21-label">
                        </li>
                    </ul>
                </div>
                <ul hidden="" class="available select__menu dropdown-menu show " id="21-values-single"
                    aria-labelledby="21-label" role="listbox">
                    <li class="has-noresults" hidden="">No results</li>
                    <li class="answer" role="option">
                        <div class="radio-group__option">
                            <input type="radio" id="21_1" class="radio-group__input" name="field21" value="1"
                                required="" aria-required="true" data-value="Roberts, Dave">
                            <label class="radio-group__label" for="21_1">Roberts, Dave</label>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
    </fieldset>
</div>
`;

const multiPersonField = `
<div class="form-group linkspace-field" data-column-id="21" data-column-type="person" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Person" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="21-label">Person</legend>
        </div>
        <div class="select-widget select-widget--required multi">
            <div class="select-widget-dropdown">
                <div class="form-control">
                    <ul class="current empty">
                        <li class="none-selected">Select option(s)</li>
                        <li data-list-id="1" data-list-item="21_1" data-list-text="Roberts, Dave" hidden="">
                            <span class="widget-value__value">Roberts, Dave</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                        <li data-list-id="4" data-list-item="21_4" data-list-text="Whizz, Billy" hidden="">
                            <span class="widget-value__value">Whizz, Billy</span>
                            <button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete"
                                title="delete" tabindex="-1">×</button>
                        </li>
                        <li class="search">
                            <input type="search" class="form-control-search" style="width:100px" placeholder="Search..."
                                aria-controls="21-values-multi" aria-expanded="false" aria-describedby="21-label">
                        </li>
                    </ul>
                </div>
                <ul hidden="hidden" class="available select__menu dropdown-menu show " id="21-values-multi"
                    aria-labelledby="21-label" role="listbox">
                    <li class="has-noresults" hidden="">No results</li>
                    <li class="answer" role="option">
                        <div class="checkbox ">
                            <input id="21_1" type="checkbox" name="field21" value="1" class=""
                                aria-labelledby="21_1-label" data-value="Roberts, Dave">
                            <label for="21_1" id="21_1-label" class="checkbox-label">Roberts, Dave</label>
                        </div>
                    </li>
                    <li class="answer" role="option">
                        <div class="checkbox ">
                            <input id="21_4" type="checkbox" name="field21" value="4" class=""
                                aria-labelledby="21_4-label" data-value="Whizz, Billy">
                            <label for="21_4" id="21_4-label" class="checkbox-label">Whizz, Billy</label>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
    </fieldset>
</div>
`;

const dateRangeField = `
<div class="form-group linkspace-field" data-column-id="22" data-column-type="daterange" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="DateRange" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <fieldset class="fieldset">
        <div class="fieldset__legend">
            <legend id="-label">DateRange</legend>
        </div>
        <div class="input-group input-daterange flex-nowrap">
            <div class="input input--date input--from input--datepicker input--required">
                <div class="input__label">
                    <label for="22_from" class="hidden">From</label>
                </div>
                <div class="input__field">
                    <input type="text" class="form-control " id="22_from" name="field22" placeholder="yyyy-mm-dd"
                        value="" data-restore-value="" data-dateformat-datepicker="yyyy-mm-dd" required=""
                        aria-required="true">
                </div>
            </div>
            <div class="input-group-addon">
                <span class="input-group-text">to</span>
            </div>
            <div class="input input--date input--to input--datepicker input--required">
                <div class="input__label">
                    <label for="22_to" class="hidden">To</label>
                </div>
                <div class="input__field">
                    <input type="text" class="form-control " id="22_to" name="field22" placeholder="yyyy-mm-dd" value=""
                        data-restore-value="" data-dateformat-datepicker="yyyy-mm-dd" required="" aria-required="true">
                </div>
            </div>
        </div>
    </fieldset>
</div>
`;

const dateRangeMultiField = `
<div class="form-group linkspace-field" data-column-id="22" data-column-type="daterange" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="DateRange" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px">
    <div class="">
        <fieldset class="fieldset fieldset--required">
            <div class="fieldset__legend">
                <legend id="22-label">DateRange</legend>
            </div>
            <div class="multiple-select">
                <div class="multiple-select__list">
                    <div class="multiple-select__row">
                        <fieldset class="fieldset" style="width: calc(100% - 100px); flex: 0 1 auto;">
                            <div class="fieldset__legend">
                                <legend id="22-label">
                                </legend>
                            </div>
                            <div class="input-group input-daterange flex-nowrap" style="width: 100%;">
                                <div class="input input--date input--from input--datepicker input--required">
                                    <div class="input__label">
                                        <label for="22_from" class="hidden">From</label>
                                    </div>
                                    <div class="input__field">
                                        <input type="text" class="form-control " id="22_from" name="field22"
                                            placeholder="yyyy-mm-dd" value="" data-restore-value=""
                                            data-dateformat-datepicker="yyyy-mm-dd" required="" aria-required="true">
                                    </div>
                                </div>
                                <div class="input-group-addon">
                                    <span class="input-group-text">to</span>
                                </div>
                                <div class="input input--date input--to input--datepicker input--required">
                                    <div class="input__label">
                                        <label for="22_to" class="hidden">To</label>
                                    </div>
                                    <div class="input__field">
                                        <input type="text" class="form-control " id="22_to" name="field22"
                                            placeholder="yyyy-mm-dd" value="" data-restore-value=""
                                            data-dateformat-datepicker="yyyy-mm-dd" required="" aria-required="true">
                                    </div>
                                </div>
                            </div>
                        </fieldset>
                        <button type="button" class="btn btn-delete btn-delete--hidden">
                            <span class="btn__title">Delete</span>
                        </button>
                    </div>
                </div>
                <button type="button" class="btn btn-add-link">
                    <span class="btn__title">Add extra value</span>
                </button>
            </div>
        </fieldset>
    </div>
</div>
`;

const dateField = `
<div class="form-group linkspace-field" data-column-id="23" data-column-type="date" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Date" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <div class="input input--date input--datepicker input--required">
        <div class="input__label">
            <label for="23">Date</label>
        </div>
        <div class="input__field">
            <input type="text" class="form-control " id="23" name="field23" placeholder="yyyy-mm-dd" value=""
                data-restore-value="" data-dateformat-datepicker="yyyy-mm-dd" required="" aria-required="true">
        </div>
    </div>
</div>
`;

const multiDateField = `
<div class="form-group linkspace-field" data-column-id="23" data-column-type="date" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Date" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px">
    <div class="">
        <fieldset class="fieldset fieldset--required">
            <div class="fieldset__legend">
                <legend id="23-label">Date</legend>
            </div>
            <div class="multiple-select">
                <div class="multiple-select__list">
                    <div class="multiple-select__row">
                        <div class="input input--date input--datepicker input--required">
                            <div class="input__field">
                                <input type="text" class="form-control " id="23" name="field23" placeholder="yyyy-mm-dd"
                                    value="" data-restore-value="" data-dateformat-datepicker="yyyy-mm-dd" required=""
                                    aria-required="true">
                            </div>
                        </div>
                        <button type="button" class="btn btn-delete btn-delete--hidden">
                            <span class="btn__title">Delete</span>
                        </button>
                    </div>
                </div>
                <button type="button" class="btn btn-add-link">
                    <span class="btn__title">Add extra value</span>
                </button>
            </div>
        </fieldset>
    </div>
</div>
`;

const intgrField = `
<div class="form-group linkspace-field" data-column-id="24" data-column-type="intgr" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Intgr" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <div class="input  input--required">
        <div class="input__label">
            <label for="24">Intgr</label>
        </div>
        <div class="input__field">
            <input type="number" class="form-control " id="24" name="field24" placeholder="" value=""
                data-restore-value="" required="" aria-required="true">
        </div>
    </div>
</div>
`;

const multiIntgrField = `
<div class="form-group linkspace-field" data-column-id="24" data-column-type="intgr" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Intgr" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px">
    <div class="">
        <fieldset class="fieldset fieldset--required">
            <div class="fieldset__legend">
                <legend id="24-label">Intgr</legend>
            </div>
            <div class="multiple-select">
                <div class="multiple-select__list">
                    <div class="multiple-select__row">
                        <div class="input  input--required">
                            <div class="input__field">
                                <input type="number" class="form-control " id="24" name="field24" placeholder=""
                                    value="" data-restore-value="" required="" aria-required="true">
                            </div>
                        </div>
                        <button type="button" class="btn btn-delete btn-delete--hidden">
                            <span class="btn__title">Delete</span>
                        </button>
                    </div>
                </div>
                <button type="button" class="btn btn-add-link">
                    <span class="btn__title">Add extra value</span>
                </button>
            </div>
        </fieldset>
    </div>
</div>
`;

const fileDom = `
<div class="form-group linkspace-field" data-column-id="25" data-column-type="file" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="File" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="25-label">File</legend>
        </div>
        <input type="hidden" name="field25" value="">
        <div class="list list--vertical list--key-value list--no-borders">
            <ul class="list__items fileupload__files">
            </ul>
        </div>
        <div class="file-upload">
            <div class="input input--file input--document input--required" data-field="field25"
                data-fileupload-url="/api/file/" data-multivalue="0">
                <div class="progress-bar__container">
                    <div class="progress-bar__progress">
                        <p class="progress-bar__percentage">0%</p>
                    </div>
                </div>
                <div class="input__label">
                    <label for="25">
                        <span class="input__file-label" role="button" aria-controls="25" tabindex="0">Choose file</span>
                    </label>
                    <div class="file">
                        <label class="file__name" for="25">No file chosen</label>
                        <button type="button" class="file__delete close" aria-label="Delete">
                            <span aria-hidden="true" class="hidden">Delete file</span>
                        </button>
                    </div>
                </div>
                <div class="input__field">
                    <input type="file" id="25" name="file" class="form-control-file " required="" aria-required="true">
                </div>
            </div>
        </div>
        <div class="drop-zone hidden" aria-hidden="true" style="display: none; visibility: hidden;">Drop files here</div>
        <div class="upload__error hidden" aria-hidden="true" style="display: none; visibility: hidden;">Error</div>
    </fieldset>
</div>
`;

const multiFileDom = `
<div class="form-group linkspace-field" data-column-id="25" data-column-type="file" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="File" data-name-short=""
    data-is-multivalue="true" data-dependent-not-shown="0" style="margin-left:0px" id="fileDom">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="25-label">File</legend>
        </div>
        <input type="hidden" name="field25" value="">
        <div class="list list--vertical list--key-value list--no-borders">
            <ul class="list__items fileupload__files">
            </ul>
        </div>
        <div class="file-upload">
            <div class="input input--file input--document input--required" data-field="field25"
                data-fileupload-url="/api/file/" data-multivalue="1">
                <div class="progress-bar__container">
                    <div class="progress-bar__progress">
                        <p class="progress-bar__percentage">0%</p>
                    </div>
                </div>
                <div class="input__label">
                    <label for="25">
                        <span class="input__file-label" role="button" aria-controls="25" tabindex="0">Choose file</span>
                    </label>
                    <div class="file">
                        <label class="file__name" for="25">No file chosen</label>
                        <button type="button" class="file__delete close" aria-label="Delete">
                            <span aria-hidden="true" class="hidden">Delete file</span>
                        </button>
                    </div>
                </div>
                <div class="input__field">
                    <input type="file" id="25" name="file" class="form-control-file " required="" aria-required="true">
                </div>
            </div>
        </div>
        <div class="drop-zone hidden" aria-hidden="true" style="display: none; visibility: hidden;">Drop files here
        </div>
        <div class="upload__error hidden" aria-hidden="true" style="display: none; visibility: hidden;">Error</div>
    </fieldset>
</div>
`;

const treeDom = `
<div class="form-group linkspace-field" data-column-id="26" data-column-type="tree" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Tree" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="26-label">Tree</legend>
        </div>
        <div class="tree " id="tree-config" data-no-initial-data="false">
            <div class="list list--horizontal list--buttons">
                <ul class="list__items">
                    <li class="list__item">
                        <button type="button" name="" value="" class="btn btn-small btn-link btn-js-tree-expand">
                            <span class="btn__title">Expand all</span>
                        </button>
                    </li>
                    <li class="list__item">
                        <button type="button" name="" value="" class="btn btn-small btn-link btn-js-tree-collapse">
                            <span class="btn__title">Collapse all</span>
                        </button>
                    </li>
                    <li class="list__item">
                        <button type="button" name="" value="" class="btn btn-small btn-link btn-js-tree-reload">
                            <span class="btn__title">Reload</span>
                        </button>
                    </li>
                </ul>
            </div>
            <div class="tree-widget-container jstree jstree-1 jstree-default" id="jstree26" data-field="field26"
                data-layout-identifier="table2" data-column-id="26" data-csrf-token="Cv3SXv22aTEGUU16OsNZt7G0Nwak0rXX"
                role="tree" tabindex="0" aria-activedescendant="9" aria-busy="false">
                <ul class="jstree-container-ul jstree-children" role="presentation">
                    <li role="none" id="9" class="jstree-node  jstree-closed">
                        <i class="jstree-icon jstree-ocl" role="presentation">
                        </i>
                        <a class="jstree-anchor" href="#" tabindex="-1" role="treeitem" aria-selected="false"
                            aria-level="1" aria-expanded="false" id="9_anchor">
                            <i class="jstree-icon jstree-themeicon" role="presentation">
                            </i>one</a>
                    </li>
                    <li role="none" id="12" class="jstree-node  jstree-closed jstree-last">
                        <i class="jstree-icon jstree-ocl" role="presentation">
                        </i>
                        <a class="jstree-anchor" href="#" tabindex="-1" role="treeitem" aria-selected="false"
                            aria-level="1" aria-expanded="false" id="12_anchor">
                            <i class="jstree-icon jstree-themeicon" role="presentation">
                            </i>two</a>
                    </li>
                </ul>
            </div>
            <input type="hidden" name="field26" value="" class="selected-tree-value">
        </div>
    </fieldset>
</div>
`;

const multiTreeDom = `
<div class="form-group linkspace-field" data-column-id="26" data-column-type="tree" data-value-selector=""
    data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Tree" data-name-short=""
    data-dependent-not-shown="0" style="margin-left:0px">
    <fieldset class="fieldset input fieldset--required">
        <div class="fieldset__legend">
            <legend id="26-label">Tree</legend>
        </div>
        <div class="tree " id="tree-config" data-no-initial-data="false">
            <div class="list list--horizontal list--buttons">
                <ul class="list__items">
                    <li class="list__item">
                        <button type="button" name="" value="" class="btn btn-small btn-link btn-js-tree-expand">
                            <span class="btn__title">Expand all</span>
                        </button>
                    </li>
                    <li class="list__item">
                        <button type="button" name="" value="" class="btn btn-small btn-link btn-js-tree-collapse">
                            <span class="btn__title">Collapse all</span>
                        </button>
                    </li>
                    <li class="list__item">
                        <button type="button" name="" value="" class="btn btn-small btn-link btn-js-tree-reload">
                            <span class="btn__title">Reload</span>
                        </button>
                    </li>
                </ul>
            </div>
            <div class="tree-widget-container jstree jstree-1 jstree-default" id="jstree26" data-field="field26"
                data-layout-identifier="table2" data-column-id="26" data-csrf-token="Cv3SXv22aTEGUU16OsNZt7G0Nwak0rXX"
                role="tree" tabindex="0" aria-activedescendant="9" aria-busy="false">
                <ul class="jstree-container-ul jstree-children" role="presentation">
                    <li role="none" id="9" class="jstree-node  jstree-closed">
                        <i class="jstree-icon jstree-ocl" role="presentation">
                        </i>
                        <a class="jstree-anchor" href="#" tabindex="-1" role="treeitem" aria-selected="false"
                            aria-level="1" aria-expanded="false" id="9_anchor">
                            <i class="jstree-icon jstree-themeicon" role="presentation">
                            </i>one</a>
                    </li>
                    <li role="none" id="12" class="jstree-node  jstree-closed jstree-last">
                        <i class="jstree-icon jstree-ocl" role="presentation">
                        </i>
                        <a class="jstree-anchor" href="#" tabindex="-1" role="treeitem" aria-selected="false"
                            aria-level="1" aria-expanded="false" id="12_anchor">
                            <i class="jstree-icon jstree-themeicon" role="presentation">
                            </i>two</a>
                    </li>
                </ul>
            </div>
            <input type="hidden" name="field26" value="" class="selected-tree-value">
        </div>
    </fieldset>
</div>
`;

describe('setFieldValue', () => {
    it('Should error if passed in value is not an array?', () => {
        const dom = $(stringDom)[0];
        document.body.appendChild(dom);
        const field = $(dom);
        expect(() => setFieldValues(field, 'test')).toThrowError('Attempt to set value for text without array');
    });

    describe('String field', () => {
        it('Should set the value of a string field', () => {
            document.body.innerHTML = '';
            const dom = $(stringDom)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            setFieldValues(field, ['test']);
            expect(field.find('input').val()).toBe('test');
        });

        it('Should set the value of a multi string field', () => {
            document.body.innerHTML = '';
            const dom = $(multiStringDom)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            setFieldValues(field, ['test1', 'test2', 'test3']);
            const inputs = $('input');
            let i = 1;
            inputs.each((_, input) => {
                expect($(input).val()).toBe(`test${i++}`);
            });
            expect(inputs.length).toBe(3);
        });
    });

    describe('Enum field', () => {
        it('Sets an enum field', () => {
            document.body.innerHTML = '';
            const dom = $(enumField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [6];
            setFieldValues(field, values);
            const input = field.find<HTMLInputElement>('input[type="radio"]');
            for (const val of input) {
                if (values.includes(Number.parseInt(val.value))) {
                    expect(val.checked).toBe(true);
                } else {
                    expect(val.checked).toBe(false);
                }
            }
        });

        it('Sets a multi enum field', () => {
            document.body.innerHTML = '';
            const dom = $(multiEnumField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [6, 7];
            setFieldValues(field, values);
            const input = field.find<HTMLInputElement>('input[type="checkbox"]');
            for (const val of input) {
                if (values.includes(Number.parseInt(val.value))) {
                    expect(val.checked).toBe(true);
                } else {
                    expect(val.checked).toBe(false);
                }
            }
        });
    });

    describe('Person field', () => {
        it('Sets a person field', () => {
            document.body.innerHTML = '';
            const dom = $(personField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [1];
            setFieldValues(field, values);
            const input = field.find<HTMLInputElement>('input[type="radio"]');
            for (const val of input) {
                if (values.includes(Number.parseInt(val.value))) {
                    expect(val.checked).toBe(true);
                } else {
                    expect(val.checked).toBe(false);
                }
            }
        });

        it('Sets a multi person field', () => {
            document.body.innerHTML = '';
            const dom = $(multiPersonField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [1, 4];
            setFieldValues(field, values);
            const input = field.find<HTMLInputElement>('input[type="checkbox"]');
            for (const val of input) {
                if (values.includes(Number.parseInt(val.value))) {
                    expect(val.checked).toBe(true);
                } else {
                    expect(val.checked).toBe(false);
                }
            }
        });
    });

    describe('dateRange', () => {
        it('Sets a date range field', () => {
            document.body.innerHTML = '';
            const dom = $(dateRangeField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [{ from: '2021-01-01', to: '2021-01-31' }];
            setFieldValues(field, values);
            const from = field.find<HTMLInputElement>('input[id$="_from"]');
            const to = field.find<HTMLInputElement>('input[id$="_to"]');
            expect(from.val()).toBe('2021-01-01');
            expect(to.val()).toBe('2021-01-31');
        });

        it('Sets a multi date range field', () => {
            document.body.innerHTML = '';
            const dom = $(dateRangeMultiField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [{ from: '2021-01-01', to: '2021-01-31' }, { from: '2021-02-01', to: '2021-02-28' }];
            setFieldValues(field, values);
            const inputs = $('input');
            let i = 0;
            inputs.each((_, input) => {
                if (i % 2 === 0) {
                    expect($(input).val()).toBe(values[i / 2].from);
                } else {
                    expect($(input).val()).toBe(values[Math.floor(i / 2)].to);
                }
                i++;
            });
            expect(inputs.length).toBe(4);
        });
    });

    describe('Date', () => {
        it('Sets a date field', () => {
            document.body.innerHTML = '';
            const dom = $(dateField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = ['2021-01-01'];
            setFieldValues(field, values);
            const input = field.find<HTMLInputElement>('input');
            expect(input.val()).toBe('2021-01-01');
        });

        it('Sets a multi date field', () => {
            document.body.innerHTML = '';
            const dom = $(multiDateField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = ['2021-01-01', '2021-01-02', '2021-01-03'];
            setFieldValues(field, values);
            const inputs = $('input');
            let i = 0;
            inputs.each((_, input) => {
                expect($(input).val()).toBe(values[i++]);
            });
            expect(inputs.length).toBe(3);
        });
    });

    describe('Intgr', () => {
        it('Sets an integer field', () => {
            document.body.innerHTML = '';
            const dom = $(intgrField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [1];
            setFieldValues(field, values);
            const input = field.find<HTMLInputElement>('input');
            expect(input.val()).toBe('1');
        });

        it('Sets a multi integer field', () => {
            document.body.innerHTML = '';
            const dom = $(multiIntgrField)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [1, 2, 3];
            setFieldValues(field, values);
            const inputs = $('input');
            let i = 1;
            inputs.each((_, input) => {
                expect($(input).val()).toBe(`${i++}`);
            });
            expect(inputs.length).toBe(3);
        });
    });

    describe('File', () => {
        it('Should set a file field', () => {
            document.body.innerHTML = '';
            const dom = $(fileDom)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $(dom);
            const values = [{ id: 1, filename: 'test' }];
            setFieldValues(field, values);
            const inputs = field.find<HTMLInputElement>('input[type="checkbox"]');
            let i = 0;
            inputs.each((_, input) => {
                expect(Number.parseInt($(input).val() ?? "")).toBe(values[i++].id);
            });
        });

        it('Should set a multi file field', () => {
            document.body.innerHTML = '';
            const dom = $(multiFileDom)[0];
            inputComponent(dom);
            buttonComponent(dom);
            multipleSelectComponent(dom);
            selectWidgetComponent(dom);
            document.body.appendChild(dom);
            const field = $("#fileDom");
            const values = [{ id: 1, filename: 'test' }, { id: 2, filename: 'test1' }];
            setFieldValues(field, values);
            const inputs = field.find('input[type="checkbox"]');
            let i = 1;
            inputs.each((_, input) => {
                expect(Number.parseInt($(input).val() as string)).toBe(i++);
            });
            expect(inputs.length).toBe(2);
        });
    });
});
