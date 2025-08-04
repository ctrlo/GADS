/* eslint-disable @typescript-eslint/no-this-alias */

import { Component, initializeRegisteredComponents } from 'component';
import 'datatables.net-bs4';
import 'datatables.net-buttons-bs4';
import 'datatables.net-responsive-bs4';
import 'datatables.net-rowreorder-bs4';
import { setupDisclosureWidgets, onDisclosureClick } from 'components/more-less/lib/disclosure-widgets';
import { moreLess } from 'components/more-less/lib/more-less';
import { bindToggleTableClickHandlers } from './toggle-table';

const MORE_LESS_TRESHOLD = 50;

//TODO: It is worth noting that there are significant changes between DataTables.net v1 and v2 (hence the major version increase)
//      We are currently using v2 in this component, but with various deprecated features in use that may need to be updated in the future
class DataTableComponent extends Component {
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.hasCheckboxes = this.el.hasClass('table-selectable');
        this.hasClearState = this.el.hasClass('table-clear-state');
        this.forceButtons = this.el.hasClass('table-force-buttons');
        this.searchParams = new URLSearchParams(window.location.search);
        this.base_url = this.el.data('href') ? this.el.data('href') : undefined;
        this.isFullScreen = false;
        this.initTable();
    }

    initTable() {
        if (this.hasClearState) {
            this.clearTableStateForPage();

            const url = new URL(window.location.href);
            url.searchParams.delete('table_clear_state');
            const targetUrl = url.toString();
            window.location.replace(targetUrl.endsWith('?') ? targetUrl.slice(0, -1) : targetUrl);

            return;
        }

        const conf = this.getConf();
        const { columns } = conf;
        this.columns = columns;
        this.el.DataTable(conf);
        this.initializingTable = true;
        $('.dt-column-order').remove(); //datatables.net adds it's own ordering class - we remove it because it's easier than rewriting basically everywhere we use datatables

        if (this.hasCheckboxes) {
            this.addSelectAllCheckbox();
        }

        if (this.el.hasClass('table-account-requests')) {
            this.modal = $.find('#userModal');
            this.initClickableTable();
            this.el.on('draw.dt', () => {
                this.initClickableTable();
            });
        }

        bindToggleTableClickHandlers(this.el);

        // Bind events to disclosure buttons and record-popup links on opening of child row
        $(this.el).on('childRow.dt', (e, show, row) => {
            const $childRow = $(row.child());
            const recordPopupElements = $childRow.find('.record-popup');

            setupDisclosureWidgets($childRow);

            if (recordPopupElements) {
                import(/* webpackChunkName: "record-popup" */ 'components/record-popup/lib/component').then(({ default: RecordPopupComponent }) => {
                    recordPopupElements.each((i, el) => {
                        new RecordPopupComponent(el);
                    });
                });
            }
        });
    }

    clearTableStateForPage() {
        for (let i = 0; i < localStorage.length; i++) {
            const storageKey = localStorage.key(i);

            if (!storageKey.startsWith('DataTables')) {
                continue;
            }

            const keySegments = storageKey.split('/');

            if (!keySegments || keySegments.length <= 1) {
                continue;
            }

            if (window.location.href.indexOf('/' + keySegments.slice(1).join('/')) !== -1) {
                localStorage.removeItem(storageKey);
            }
        }
    }

    initClickableTable() {
        const links = this.el.find('tbody td .link');
        // Remove all existing click events to prevent multiple bindings
        links.off('click');
        links.off('focus');
        links.off('blur');
        links.on('click', (ev) => { this.handleClick(ev); });
        links.on('focus', (ev) => { this.toggleFocus(ev, true); });
        links.on('blur', (ev) => { this.toggleFocus(ev, false); });
    }

    toggleFocus(ev, hasFocus) {
        const row = $(ev.target).closest('tr');
        if (hasFocus) {
            row.addClass('tr--focus');
        } else {
            row.removeClass('tr--focus');
        }
    }

    handleClick(ev) {
        const rowClicked = $(ev.target).closest('tr');
        ev.preventDefault();
        this.fillModalData(rowClicked);
        $(this.modal).modal('show');
    }

    fillModalData(row) {
        const fields = $(this.modal).find('input, textarea');
        const btnReject = $(this.modal).find('.btn-js-reject-request-send');
        const id = parseInt($(row).find('td[data-id]')
            .data('id'), 10);

        if (id) $(this.modal).data('config').id = id;

        if (btnReject && id && (!isNaN(id))) {
            btnReject.val(id);
        }

        fields.each((i, field) => {
            const fieldName = $(field).attr('name');
            const fieldValue = $(row).find(`td[data-${fieldName}]`)
                .data(fieldName);

            if (fieldName && fieldValue) {
                const $field = $(field);
                $field.data('original-value', fieldValue);
                if ($field.is(':radio, :checkbox')) {
                    if ($field.val() == fieldValue) {
                        $field.trigger('click');
                    }
                } else {
                    $field.data('original-value', fieldValue);
                    $field.trigger('change');
                    $field.val(fieldValue);
                }
            }
        });
    }

    getCheckboxElement(id, label) {
        return (
            '<div class=\'checkbox\'>' +
            `<input id='dt_checkbox_${id}' type='checkbox' />` +
            `<label for='dt_checkbox_${id}'><span>${label}</span></label>` +
            '</div>'
        );
    }

    addSelectAllCheckbox() {
        const $selectAllElm = this.el.find('thead th.check');
        const $checkBoxes = this.el.find('tbody .check .checkbox input');

        if ($selectAllElm.length) {
            $selectAllElm.html(this.getCheckboxElement('all', 'Select all'));
        }

        // Check if all checkboxes are checked and the 'select all' checkbox needs to be checked
        this.checkSelectAll($checkBoxes, $selectAllElm.find('input'));

        $checkBoxes.on('click', () => {
            this.checkSelectAll($checkBoxes, $selectAllElm.find('input'));
        });

        // Check if the 'select all' checkbox is checked and all checkboxes need to be checked
        $selectAllElm.find('input').on('click', (ev) => {
            const checkbox = $(ev.target);

            if ($(checkbox).is(':checked')) {
                this.checkAllCheckboxes($checkBoxes, true);
            } else {
                this.checkAllCheckboxes($checkBoxes, false);
            }
        });
    }

    checkAllCheckboxes($checkBoxes, bCheckAll) {
        if (bCheckAll) {
            $checkBoxes.prop('checked', true);
        } else {
            $checkBoxes.prop('checked', false);
        }
    }

    checkSelectAll($checkBoxes, $selectAllCheckBox) {
        let bSelectAll = true;

        $checkBoxes.each((i, checkBox) => {
            if (!checkBox.checked) {
                $selectAllCheckBox.prop('checked', false);
                bSelectAll = false;
            }
        });

        if (bSelectAll) {
            $selectAllCheckBox.prop('checked', true);
        }
    }

    addSortButton(dataTable, column, headerContent) {
        const $header = $(column.header());
        const $button = $(`
      <button class="data-table__sort" type="button">
        <span>${headerContent}</span>
        <span class="btn btn-sort">
          <span>Sort</span>
        </span>
      </button>`
        );

        $header
            .off()
            .find('.data-table__header-wrapper')
            .html($button);

        dataTable.order.listener($button, column.index());
    }

    toggleFilter(column) {
        const $header = $(column.header());

        if (column.search() !== '') {
            $header.find('.data-table__header-wrapper').addClass('filter');
            $header.find('.data-table__clear').show();
        } else {
            $header.find('.data-table__header-wrapper').removeClass('filter');
            $header.find('.data-table__clear').hide();
        }
    }

    // Self reference included due to scoping
    async addSearchDropdown(column, id, index) {
        const $header = $(column.header());
        const title = $header.text().trim();
        const searchValue = column.search();
        const self = this;
        const { context } = column;
        const { oAjaxData } = context[0];
        const { columns } = oAjaxData;
        const columnId = columns[column.index()].name;
        const col = this.columns[column.index()];

        const $searchElement = $(
            `<div class='data-table__search'>
        <button
          class='btn btn-search dropdown-toggle'
          id='search-toggle-${index}'
          type='button'
          data-toggle='dropdown'
          aria-expanded='false'
          data-boundary='viewport'
          data-reference='parent'
          data-target="[data-ddl='ddl_${index}']"
          data-focus="[data-ddl='ddl_${index}']"
        >
          <span>Search in ${title}</span>
        </button>
        <div class='dropdown-menu p-2' aria-labelledby='search-toggle-${index}'>
          <label>
            <div class='input'>
            </div>
          </label>
          <button type='button' class='btn btn-link btn-small data-table__clear hidden'>
            <span>Clear filter</span>
          </button>
        </div>
      </div>`
        );

        /* Construct search box for filtering. If the filter has a typeahead and if
         * it uses an ID rather than text, then add a second (hidden) input field
         * to store the ID. If we already have a stored search value for the
         * column, then if it's an ID we will need to look up the textual value for
         * insertion into the visible input */
        const $searchInput = $(`<input class='form-control form-control-sm' type='text' placeholder='Search' value='${searchValue}'/>`);
        $searchInput.appendTo($('.input', $searchElement));
        if (col.typeahead_use_id) {
            $searchInput.after('<input type="hidden" class="search">');
            if (searchValue) {
                const response = await fetch(this.getApiEndpoint(columnId) + searchValue + '&use_id=1');
                const data = await response.json();
                if (!data.error) {
                    if (data.records.length != 0) {
                        $searchInput.val(data.records[0].label);
                        $('input.search', $searchElement).val(data.records[0].id)
                            .trigger('change');
                    }
                }
            }
        } else {
            $('input', $searchElement).addClass('search');
        }

        $header.find('.data-table__header-wrapper').prepend($searchElement);

        this.toggleFilter(column);

        if (col && col.typeahead) {
            import(/*webpackChunkName: "typeahead" */ 'util/typeahead')
                .then(({ default: TypeaheadBuilder }) => {
                    const builder = new TypeaheadBuilder();
                    builder
                        .withAjaxSource(this.getApiEndpoint(columnId))
                        .withInput($('input', $header))
                        .withAppendQuery()
                        .withDefaultMapper()
                        .withName(columnId.replace(/\s+/g, '') + 'Search')
                        .withCallback((data) => {
                            if (col.typeahead_use_id) {
                                $searchInput.val(data.name);
                                $('input.search', $searchElement).val(data.id)
                                    .trigger('change');
                            } else {
                                $('input', $searchElement).addClass('search')
                                    .val(data.name)
                                    .trigger('change');
                            }
                        })
                        .build();
                });
        }

        // Apply the search
        $('input.search', $header).on('change', function (ev) {
            let value = this.value || ev.target.value;
            if (column.search() !== value) {
                column
                    .search(value)
                    .draw();
            }

            self.toggleFilter(column);

            // Update or add the filter to the searchParams
            if (self.searchParams.has(id)) {
                self.searchParams.set(id, this.value);
            } else {
                self.searchParams.append(id, this.value);
            }

            // Update URL. Do not reload otherwise the data is fetched twice (already
            // redrawn in the previous statement)
            const url = `${window.location.href.split('?')[0]}?${self.searchParams.toString()}`;
            window.history.replaceState(null, '', url);
        });

        // Clear the search
        $('.data-table__clear', $header).on('click', function () {
            $(this).closest('.dropdown-menu')
                .find('input')
                .val('');
            column
                .search('')
                .draw();

            self.toggleFilter(column);

            // Delete the filter from the searchparams and update and reload the url
            if (self.searchParams.has(id)) {
                self.searchParams.delete(id);
                let url = `${window.location.href.split('?')[0]}`;

                if (self.searchParams.entries().next().value !== undefined) {
                    url += `?${self.searchParams.toString()}`;
                }

                // Update URL. See comment above about the same
                window.history.replaceState(null, '', url);
            }
        });
    }

    getApiEndpoint(columnId) {
        const table = $('body').data('layout-identifier');
        return `/${table}/match/layout/${columnId}?q=`;
    }

    encodeHTMLEntities(text) {
        return $('<textarea/>').text(text)
            .html();
    }

    decodeHTMLEntities(text) {
        return $('<textarea/>').html(text)
            .text();
    }

    renderMoreLess(strHTML, strColumnName) {
        if (strHTML.toString().length > MORE_LESS_TRESHOLD) {
            return (
                `<div class="more-less" data-column="${strColumnName}">
          ${strHTML}
        </div>`
            );
        }
        return strHTML;
    }

    renderDefault(data) {
        let strHTML = '';

        if (!data.values || !data.values.length) {
            return strHTML;
        }

        data.values.forEach((value, i) => {
            strHTML += this.encodeHTMLEntities(value);
            strHTML += (data.values.length > (i + 1)) ? ', ' : '';
        });

        return this.renderMoreLess(strHTML, data.name);
    }

    renderId(data) {
        let retval = '';
        const id = data.values[0];
        if (!id) return retval;
        if (data.parent_id) {
            retval = `<span title="Child record with parent record ${data.parent_id}">${data.parent_id} &#8594;</span> `;
        }
        return retval + `<a href="${this.base_url}/${id}">${id}</a>`;
    }

    renderPerson(data) {
        let strHTML = '';

        if (!data.values.length) {
            return strHTML;
        }

        data.values.forEach((value) => {
            if (value.details.length) {
                let thisHTML = '<div>';
                value.details.forEach((detail) => {
                    const strDecodedValue = this.encodeHTMLEntities(detail.value);
                    if (detail.type === 'email') {
                        thisHTML += `<p>E-mail: <a href="mailto:${strDecodedValue}">${strDecodedValue}</a></p>`;
                    } else {
                        thisHTML += `<p>${this.encodeHTMLEntities(detail.definition)}: ${strDecodedValue}</p>`;
                    }
                });
                thisHTML += '</div>';
                strHTML += (
                    `<div class="position-relative">
            <button class="btn btn-small btn-inverted btn-info trigger" aria-expanded="false" type="button">
              ${this.encodeHTMLEntities(value.text)}
              <span class="invisible">contact details</span>
            </button>
            <div class="person contact-details expandable popover card card--secundary">
              ${thisHTML}
            </div>
          </div>`
                );
            }
        });

        return strHTML;
    }

    renderFile(data) {
        let strHTML = '';

        if (!data.values.length) {
            return strHTML;
        }

        data.values.forEach((file) => {
            strHTML += `<a href="/file/${file.id}">`;
            if (file.mimetype.match('^image/')) {
                strHTML += `<img class="autosize" src="/file/${file.id}"></img>`;
            } else {
                strHTML += `${this.encodeHTMLEntities(file.name)}<br>`;
            }
            strHTML += '</a>';
        });

        return strHTML;
    }

    renderRag(data) {
        let strRagType = '';
        const arrRagTypes = {
            a_grey: 'undefined',
            b_red: 'danger',
            b_attention: 'attention',
            c_amber: 'warning',
            c_yellow: 'advisory',
            d_green: 'success',
            d_blue: 'complete',
            e_purple: 'unexpected'
        };

        if (data.values.length) {
            const value = data.values[0]; // There's always only one rag
            strRagType = arrRagTypes[value] || 'blank';
        } else {
            strRagType = 'blank';
        }

        const text = $('#rag_' + strRagType + '_meaning').text();

        return `<span class="rag rag--${strRagType}" title="${text}" aria-labelledby="rag_${strRagType}_meaning"><span>✗</span></span>`;
    }

    renderCurCommon(data) {
        let strHTML = '';

        if (data.values.length === 0) {
            return strHTML;
        }

        strHTML = this.renderCurCommonTable(data);
        return this.renderMoreLess(strHTML, data.name);
    }

    renderCurCommonTable(data) {
        let strHTML = '';

        if (data.values.length === 0) {
            return strHTML;
        }
        if (data.values[0].fields.length === 0) {
            // No columns visible to user
            return strHTML;
        }

        strHTML += '<table class="table-curcommon">';

        data.values.forEach((row) => {
            strHTML += `<tr role="button" tabindex="0" class="link record-popup" data-record-id="${row.record_id}"`;
            if (row.version_id) {
                strHTML += `data-version-id="${row.version_id}"`;
            }
            strHTML += '>';
            if (row.status) {
                strHTML += `<td><em>${row.status}:</em></td>`;
            }

            row.fields.forEach((field) => {
                strHTML += `<td class="${field.type}">${this.renderDataType(field)}</td>`;
            });
            strHTML += '</tr>';
        });

        strHTML += '</table>';

        if (data.limit_rows && data.values.length >= data.limit_rows) {
            strHTML +=
                `<p><em>(showing maximum ${data.limit_rows} rows.
          <a href="/${data.parent_layout_identifier}/data?curval_record_id=${data.curval_record_id}&curval_layout_id=${data.column_id}">view all</a>)</em>
        </p>`;
        }

        return strHTML;
    }

    renderDataType(data) {
        switch (data.type) {
            case 'id':
                return this.renderId(data);
            case 'person':
            case 'createdby':
                return this.renderPerson(data);
            case 'curval':
            case 'autocur':
            case 'filval':
                return this.renderCurCommon(data);
            case 'file':
                return this.renderFile(data);
            case 'rag':
                return this.renderRag(data);
            default:
                return this.renderDefault(data);
        }
    }

    renderData(type, row, meta) {
        const strColumnName = meta ? meta.settings.oAjaxData.columns[meta.col].name : '';
        const data = row[strColumnName];

        if (typeof data !== 'object') {
            return '';
        }

        return this.renderDataType(data);
    }

    getConf(overrides = undefined) {
        const confData = this.el.data('config');
        let conf = {};

        if (typeof confData === 'string') {
            conf = JSON.parse(atob(confData));
        } else if (typeof confData === 'object') {
            conf = confData;
        }

        if (overrides) {
            for (const key in overrides) {
                conf[key] = overrides[key];
            }
        }

        conf.columns.forEach((column) => {
            column.orderable = column.orderable === 1;
        });

        if (conf.serverSide) {
            conf.columns.forEach((column) => {
                column.render = (data, type, row, meta) => this.renderData(type, row, meta);
            });
        }

        const self = this;

        conf['initComplete'] = (settings, json) => {
            const tableElement = this.el;
            const dataTable = tableElement.DataTable();

            this.json = json || undefined;

            if (this.initializingTable || conf.reinitialize) {
                dataTable.columns().every(function (index) {
                    const column = this;
                    const $header = $(column.header());

                    const headerContent = $header.html();
                    $header.html(`<div class='data-table__header-wrapper position-relative ${column.search() ? 'filter' : ''}' data-ddl='ddl_${index}'>${headerContent}</div>`);

                    // Add sort button to column header
                    if ($header.hasClass('dt-orderable-asc') || $header.hasClass('dt-orderable-desc')) {
                        self.addSortButton(dataTable, column, headerContent);
                    }

                    // Add button to column headers (only serverside tables)
                    if ((conf.serverSide) && (tableElement.hasClass('table-search'))) {
                        const id = settings.oAjaxData.columns[index].name;

                        if (self.searchParams.has(id)) {
                            column.search(self.searchParams.get(id)).draw();
                        }

                        self.addSearchDropdown(column, id, index);
                    }
                    return true;
                });

                // If the table has not wrapped (become responsive) then hide the "Full screen" toggle button
                if (!this.el.hasClass('collapsed')) {
                    if (this.el.closest('.dataTables_wrapper').find('.btn-toggle-off').length) {
                        this.el.closest('.dataTables_wrapper').find('.dataTables_toggle_full_width')
                            .hide();
                    }
                }

                this.initializingTable = false;
            }
        };

        conf['footerCallback'] = function () {
            const api = this.api();
            // Add aggregate values to table if configured
            const agg = api.ajax && api.ajax.json() && api.ajax.json().aggregate;
            if (agg) {
                const cols = api.settings()[0].oAjaxData.columns;
                api.columns().every(function () {
                    const idx = this.index();
                    const { name } = cols[idx];
                    if (agg[name]) {
                        $(this.footer()).html(
                            self.renderDataType(agg[name])
                        );
                    }
                    return true;
                });
            }
        };

        conf['drawCallback'] = () => {

            //Re-initialize more-less components after initialisation is complete
            moreLess.reinitialize();

            // (Re)enable wide-table toggle button each time. It is disabled during
            // any drawing to prevent it being clicked multiple times during a draw
            this.el.DataTable().button(0)
                .enable();

            this.bindClickHandlersAfterDraw(conf);
        };

        conf['buttons'] = [
            {
                text: 'Full screen',
                enabled: false,
                attr: {
                    id: 'full-screen-btn'
                },
                className: 'btn btn-small btn-toggle-off',
                action: (e) => {
                    this.toggleFullScreenMode(e);
                }
            }
        ];

        return conf;
    }

    /*
      For some reason, the current code that is present doesn't enable/disable the button as expected; it will disable the button, but will not re-enable the button.
      I have tried manually changing the DOM, as well as the methods already present in the code, and I currently believe there is a bug within the DataTables button
      code that is meaning that this won't change (although I am open to the fact that I am being a little slow and missing something glaringly obvious).
    */
     
    toggleFullScreenMode(buttonElement) {
        const table = document.querySelector('table.data-table');
        const currentTable = $(table);
        if (currentTable && $.fn.dataTable.isDataTable(currentTable)) {
            currentTable.DataTable().destroy();
        }
        if (!this.isFullScreen) {
            // Create new modal
            const newModal = document.createElement('div');
            newModal.id = 'table-modal';
            newModal.classList.add('table-modal');
            newModal.classList.add('data-table__container--scrollable');

            // Move data table into new modal
            newModal.append(table);
            document.body.appendChild(newModal);
            if (currentTable && !($.fn.dataTable.isDataTable(currentTable))) {
                currentTable.DataTable(this.getConf({ responsive: false, reinitialize: true }));
            }

            $(document).on('keyup', (ev) => {
                if (ev.key === 'Escape') {
                    this.toggleFullScreenMode(buttonElement);
                }
            });
        } else {
            // Move data table back to original page
            const mainContent = document.querySelector('.content-block__main-content');
            if (!mainContent) {
                console.warn('Failed to close full screen; missing main content');
                return;
            }

            mainContent.appendChild(table);
            if (currentTable && !($.fn.dataTable.isDataTable(currentTable))) {
                currentTable.DataTable(this.getConf({ reinitialize: true }));
            }
            // Remove the modal
            document.querySelector('#table-modal').remove();

            $(document).off('keyup');
        }

        // Toggle the full screen button
        this.isFullScreen = !this.isFullScreen;
        $('#full-screen-btn').removeClass(this.isFullScreen ? 'btn-toggle-off' : 'btn-toggle');
        $('#full-screen-btn').addClass(this.isFullScreen ? 'btn-toggle' : 'btn-toggle-off');
    }

    bindClickHandlersAfterDraw(conf) {
        const tableElement = this.el;
        const rows = tableElement.DataTable().rows({ page: 'current' })
            .data();

        if (rows && this.base_url) {
            // Add click handler to tr to open a record by id
            $(tableElement).find('> tbody > tr')
                .each((i, el) => {
                    const data = rows[i] ? rows[i] : undefined;
                    if (data) {
                    // URL will be record link for standard view, or filtered URL for
                    // grouped view (in which case _count parameter will be present not _id)
                        const url = data['_id'] ? `${this.base_url}/${data['_id']}` : `?${data['_count']['url']}`;

                        $(el).find('td:not(".dtr-control")')
                            .on('click', (ev) => {
                                // Only for table cells that are not part of a record-popup table row
                                if (!ev.target.closest('.record-popup')) {
                                    window.location = url;
                                }
                            });
                    }
                });
        }

        if (conf.serverSide) {
            // Add click handler to disclosure widgets that are not part of a more-less component
            const $disclosureWidgets = $(tableElement).find(':not(.more-less) > .trigger[aria-expanded]');

            // First, remove all existing click events to prevent multiple bindings
            $disclosureWidgets.off('click', onDisclosureClick);
            $disclosureWidgets.on('click', onDisclosureClick);

            initializeRegisteredComponents(this.element);
        }
    }
}

export default DataTableComponent;
