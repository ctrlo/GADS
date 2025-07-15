import "bootstrap";
import "@popperjs/core";
import { Component, initializeRegisteredComponents } from 'component'
import 'datatables.net-bs5'
import 'datatables.net-responsive-bs5'
import 'datatables.net-rowreorder-bs5'
import 'datatables.net-buttons-bs5'
import './DataTablesPlugins'
import { setupDisclosureWidgets, onDisclosureClick } from 'components/more-less/lib/disclosure-widgets'
import { moreLess } from 'components/more-less/lib/more-less'
import { bindToggleTableClickHandlers } from './toggle-table'
import { createElement } from "util/domutils";
import { Config } from "datatables.net-bs5";

const MORE_LESS_TRESHOLD = 50

/**
 * Datatable Component class
 */
class DataTableComponent extends Component {
  /**
   * Create a new Datatable component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.hasCheckboxes = this.el.hasClass('table-selectable')
    this.hasClearState = this.el.hasClass('table-clear-state')
    this.forceButtons = this.el.hasClass('table-force-buttons')
    this.hasSearch = this.el.hasClass('table-search')
    this.searchParams = new URLSearchParams(window.location.search)
    this.base_url = this.el.data('href') ? this.el.data('href') : undefined
    this.isFullScreen = false
    this.initializingTable = true

    this.initTable()
  }

  /**
   * Initialise the datatable
   */
  initTable() {
    if (this.hasClearState) {
      this.clearTableStateForPage()

      const url = new URL(window.location.href)
      url.searchParams.delete('table_clear_state')
      const targetUrl = url.toString()
      window.location.replace(targetUrl.endsWith('?') ? targetUrl.slice(0, -1) : targetUrl)

      return
    }

    const conf = this.getConf()
    const { columns } = conf
    this.columns = columns
    const dt = this.el.DataTable(conf)

    $(window).on('resize', () => {
      this.el.DataTable().responsive.recalc()
    });

    this.initializingTable = true

    if (this.hasCheckboxes) {
      this.addSelectAllCheckbox()
    }

    if (this.el.hasClass('table-account-requests')) {
      this.modal = $('#userModal')
      this.initClickableTable()
      this.el.on('draw.dt', () => {
        this.initClickableTable()
      })
    }

    bindToggleTableClickHandlers(this.el)

    // Bind events to disclosure buttons and record-popup links on opening of child row
    $(this.el).on('childRow.dt', (_e, _show, row) => {
      const $childRow = $(row.child())
      const recordPopupElements = $childRow.find('.record-popup')
      const bsPopupElements = $childRow.find('[bs-data-toggle="popover"]');

      setupDisclosureWidgets($childRow)

      if (recordPopupElements) {
        import(/* webpackChunkName: "record-popup" */ 'components/record-popup/lib/component').then(({ default: RecordPopupComponent }) => {
          recordPopupElements.each((_i, el) => {
            new RecordPopupComponent(el)
          });
        });
      }

      if (bsPopupElements && bsPopupElements.length) {
        import(/* webpackChunkName: "bootstrap-popover" */ 'components/bootstrap-popover/lib/component').then(({ default: BootstrapPopoverComponent }) => {
          bsPopupElements.each((_i, el) => {
            new BootstrapPopoverComponent(el);
          });
        });
      }
    });
  }

  /**
   * Clear the table state for the page
   */
  clearTableStateForPage() {
    for (let i = 0; i < localStorage.length; i++) {
      const storageKey = localStorage.key(i)

      if (!storageKey.startsWith("DataTables")) {
        continue;
      }

      const keySegments = storageKey.split('/')

      if (!keySegments || keySegments.length <= 1) {
        continue;
      }

      if (window.location.href.indexOf('/' + keySegments.slice(1).join('/')) !== -1) {
        localStorage.removeItem(storageKey)
      }
    }
  }

  /**
   * Initialise the clickable handlers for table rows
   */
  initClickableTable() {
    const links = this.el.find('tbody td .link')
    // Remove all existing click events to prevent multiple bindings
    links.off('click')
    links.off('focus')
    links.off('blur')
    links.on('click', (ev) => {
      this.handleClick(ev)
    })
    links.on('focus', (ev) => {
      this.toggleFocus(ev, true)
    })
    links.on('blur', (ev) => {
      this.toggleFocus(ev, false)
    })
  }

  /**
   * Toggle the focus class on the row
   * @param {JQuery.Event} ev The event object
   * @param {boolean} hasFocus Whether the element has focus
   */
  toggleFocus(ev, hasFocus) {
    const row = $(ev.target).closest('tr')
    if (hasFocus) {
      row.addClass('tr--focus')
    } else {
      row.removeClass('tr--focus')
    }
  }

  /**
   * Click handler for the table rows
   * @param {JQuery.Event} ev The event object
   */
  handleClick(ev) {
    const rowClicked = $(ev.target).closest('tr')
    ev.preventDefault()
    this.fillModalData(rowClicked)
    $(this.modal).modal('show')
  }

  /**
   * Fill the modal with data from the row
   * @param {*} row The row to use to set the data
   */
  fillModalData(row) {
    const fields = $(this.modal).find('input, textarea')
    const btnReject = $(this.modal).find('.btn-js-reject-request-send')
    const id = parseInt($(row).find(`td[data-id]`).data('id'), 10)

    if (id) $(this.modal).data('config').id = id

    if (btnReject && id && (!isNaN(id))) {
      btnReject.val(id)
    }

    fields.each((_i, field) => {
      const fieldName = $(field).attr('name')
      const fieldValue = $(row).find(`td[data-${fieldName}]`).data(fieldName)

      if (fieldName && fieldValue) {
        const $field = $(field)
        $field.data('original-value', fieldValue)
        if ($field.is(":radio, :checkbox")) {
          if ($field.val() == fieldValue) {
            $field.trigger("click")
          }
        } else {
          $field.data('original-value', fieldValue)
          $field.trigger('change')
          $field.val(fieldValue)
        }
      }
    })
  }

  /**
   * Get the checkbox element
   * @param {string} id The ID of the checkbox
   * @param {string} label The label for the checkbox
   * @returns {string} The element HTML
   */
  getCheckboxElement(id, label) {
    return (
      `<div class='checkbox'>` +
      `<input id='dt_checkbox_${id}' type='checkbox' />` +
      `<label class="form-label" for='dt_checkbox_${id}'><span>${label}</span></label>` +
      '</div>'
    )
  }

  /**
   * Add a select all checkbox
   */
  addSelectAllCheckbox() {
    const $selectAllElm = this.el.find('thead th.check')
    const $checkBoxes = this.el.find('tbody .check .checkbox input')

    if ($selectAllElm.length) {
      $selectAllElm.html(this.getCheckboxElement('all', 'Select all'))
    }

    // Check if all checkboxes are checked and the 'select all' checkbox needs to be checked
    this.checkSelectAll($checkBoxes, $selectAllElm.find('input'))

    $checkBoxes.on('click', () => {
      this.checkSelectAll($checkBoxes, $selectAllElm.find('input'))
    })

    // Check if the 'select all' checkbox is checked and all checkboxes need to be checked
    $selectAllElm.find('input').on('click', (ev) => {
      const checkbox = $(ev.target)

      if ($(checkbox).is(':checked')) {
        this.checkAllCheckboxes($checkBoxes, true)
      } else {
        this.checkAllCheckboxes($checkBoxes, false)
      }
    })
  }

  /**
   * Check or uncheck all checkboxes
   * @param {JQuery} $checkBoxes The checkboxes to check
   * @param {boolean} bCheckAll True to check all checkboxes, false to uncheck all
   */
  checkAllCheckboxes($checkBoxes, bCheckAll) {
    if (bCheckAll) {
      $checkBoxes.prop('checked', true)
    } else {
      $checkBoxes.prop('checked', false)
    }
  }

  /**
   * Check all checkboxes in a group
   * @param {JQuery} $checkBoxes The checkboxes to check
   * @param {JQuery} $selectAllCheckBox The select all checkbox
   */
  checkSelectAll($checkBoxes, $selectAllCheckBox) {
    let bSelectAll = true

    $checkBoxes.each((_i, checkBox) => {
      if (!checkBox.checked) {
        $selectAllCheckBox.prop('checked', false)
        bSelectAll = false
      }
    })

    if (bSelectAll) {
      $selectAllCheckBox.prop('checked', true)
    }
  }

  /**
   * Toggle filtering on a column
   * @param {*} column The column to toggle filtering on
   */
  toggleFilter(column) {
    const $header = $(column.header())

    if (column.search() !== '') {
      $header.find('.data-table__header-wrapper').addClass('filter')
      // $header.find('.data-table__clear').show()
    } else {
      $header.find('.data-table__header-wrapper').removeClass('filter')
      // $header.find('.data-table__clear').hide()
    }
  }

  /**
   * Get the API endpoint for searches
   * @param {*} columnId The ID of the column to get the API endpoint for
   * @returns {string} The API endpoint
   */
  getApiEndpoint(columnId) {
    const table = $("body").data("layout-identifier");
    return `/${table}/match/layout/${columnId}?q=`;
  }

  /**
   * Encode HTML entities in a string
   * @param {string} text The text to encode
   * @returns {string} A string with HTML entities encoded
   */
  encodeHTMLEntities(text) {
    return $("<textarea/>").text(text).html();
  }

  /**
   * Render a more/less component if required
   * @param {string} strHTML The HTML to render
   * @param {string} strColumnName The column name
   * @returns {string} The HTML for a more/less control if required, otherwise the original HTML
   */
  renderMoreLess(strHTML, strColumnName) {
    if (strHTML.toString().length > MORE_LESS_TRESHOLD) {
      return (
        `<div class="more-less" data-column="${strColumnName}">
          ${strHTML}
        </div>`
      )
    }
    return strHTML
  }

  /**
   * Render default data types
   * @param {*} data The data to render
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderDefault(data) {
    let strHTML = ''

    if (!data.values || !data.values.length) {
      return strHTML
    }

    data.values.forEach((value, i) => {
      strHTML += this.encodeHTMLEntities(value)
      strHTML += (data.values.length > (i + 1)) ? `, ` : ``
    })

    return this.renderMoreLess(strHTML, data.name)
  }

  /**
   * Render an ID field
   * @param {*} data The data to render
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderId(data) {
    let retval = ''
    const id = data.values[0]
    if (!id) return retval
    if (data.parent_id) {
      retval = `<span title="Child record with parent record ${data.parent_id}">${data.parent_id} &#8594;</span> `
    }
    return retval + `<a href="${this.base_url}/${id}">${id}</a>`
  }

  /**
   * Render a person field
   * @param {*} data The data to render
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderPerson(data) {
    let strHTML = ''

    if (!data.values.length) {
      return strHTML
    }

    data.values.forEach((value) => {
      if (value.details.length) {
        let thisHTML = `<div>`
        value.details.forEach((detail) => {
          const strDecodedValue = this.encodeHTMLEntities(detail.value)
          if (detail.type === 'email') {
            thisHTML += `<p>E-mail: <a href="mailto:${strDecodedValue}">${strDecodedValue}</a></p>`
          } else {
            thisHTML += `<p>${this.encodeHTMLEntities(detail.definition)}: ${strDecodedValue}</p>`
          }
        })
        thisHTML += `</div>`
        strHTML += (
          `<div class="position-relative">
            <button class="btn btn-small btn-inverted btn-info trigger" aria-expanded="false" type="button" data-bs-toggle="popover" data-bs-placement="bottom" data-bs-content='${thisHTML}'>
              ${this.encodeHTMLEntities(value.text)}
              <span class="invisible">contact details</span>
            </button>
          </div>`
        )
      }
    })

    return strHTML
  }

  /**
   * Render a file datum
   * @param {*} data The data to render
   * @returns {string} The HTML representation of the data as it should be rendered
   */
  renderFile(data) {
    let strHTML = ''

    if (!data.values.length) {
      return strHTML
    }

    data.values.forEach((file) => {
      strHTML += `<a href="/file/${file.id}">`
      if (file.mimetype.match('^image/')) {
        strHTML += `<img alt="image of ${file.id}" class="autosize" src="/file/${file.id}">`
      } else {
        strHTML += `${this.encodeHTMLEntities(file.name)}<br>`
      }
      strHTML += `</a>`
    })

    return strHTML
  }

  /**
   * Render a RAG (Red, Amber, Green) datum
   * @param {*} data The data to render
   * @returns {string} The HTML representation of the data as it should be rendered
   */
  renderRag(data) {
    let strRagType;
    const arrRagTypes = {
      a_grey: 'undefined',
      b_red: 'danger',
      b_attention: 'attention',
      c_amber: 'warning',
      c_yellow: 'advisory',
      d_green: 'success',
      d_blue: 'complete',
      e_purple: 'unexpected'
    }

    if (data.values.length) {
      const value = data.values[0] // There's always only one rag
      strRagType = arrRagTypes[value] || 'blank'
    } else {
      strRagType = 'blank'
    }

    const text = $('#rag_' + strRagType + '_meaning').text();

    return `<span class="rag rag--${strRagType}" title="${text}" aria-labelledby="rag_${strRagType}_meaning"><span>✗</span></span>`
  }

  /**
   * Render a curval datum
   * @param {*} data The data to render
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderCurCommon(data) {
    let strHTML = ''

    if (data.values.length === 0) {
      return strHTML
    }

    strHTML = this.renderCurCommonTable(data)
    return this.renderMoreLess(strHTML, data.name)
  }

  /**
   * Render a curval table
   * @param {*} data The data to render
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderCurCommonTable(data) {
    let strHTML = ''

    if (data.values.length === 0) {
      return strHTML
    }
    if (data.values[0].fields.length === 0) {
      // No columns visible to user
      return strHTML
    }

    strHTML += `<table class="table-curcommon">`

    data.values.forEach((row) => {
      strHTML += `<tr role="button" tabindex="0" class="link record-popup" data-record-id="${row.record_id}"`
      if (row.version_id) {
        strHTML += `data-version-id="${row.version_id}"`
      }
      strHTML += `>`
      if (row.status) {
        strHTML += `<td><em>${row.status}:</em></td>`
      }

      row.fields.forEach((field) => {
        strHTML += `<td class="${field.type}">${this.renderDataType(field)}</td>`
      })
      strHTML += `</tr>`
    })

    strHTML += `</table>`

    if (data.limit_rows && data.values.length >= data.limit_rows) {
      strHTML +=
        `<p><em>(showing maximum ${data.limit_rows} rows.
          <a href="/${data.parent_layout_identifier}/data?curval_record_id=${data.curval_record_id}&curval_layout_id=${data.column_id}">view all</a>)</em>
        </p>`
    }

    return strHTML
  }

  /**
   * Render data according to it's datatype
   * @param {*} data The data to render
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderDataType(data) {
    switch (data.type) {
      case 'id':
        return this.renderId(data)
      case 'person':
      case 'createdby':
        return this.renderPerson(data);
      case 'curval':
      case 'autocur':
      case 'filval':
        return this.renderCurCommon(data)
      case 'file':
        return this.renderFile(data)
      case 'rag':
        return this.renderRag(data)
      default:
        return this.renderDefault(data)
    }
  }

  /**
   * Callback to render data in the Datatable
   * @param {*} type The datatype (unused)
   * @param {*} row The row to render the data on
   * @param {*} meta The row metadata
   * @returns {string} An HTML representation of the data as it should be rendered
   */
  renderData(type, row, meta) {
    const strColumnName = meta ? meta.settings.oAjaxData.columns[meta.col].name : ""
    const data = row[strColumnName]

    if (typeof data !== 'object') {
      return ''
    }

    return this.renderDataType(data)
  }

  /**
   * Get the datatable configuration
   * @param { Config } overrides Any overrides for the configuration
   * @returns { Config } A configuration object for the datatable
   */
  getConf(overrides = undefined) {
    const confData = this.el.data('config')
    let conf = {}

    if (typeof confData == 'string') {
      conf = JSON.parse(atob(confData))
    } else if (typeof confData == 'object') {
      conf = confData;
    } else {
      throw new Error('DataTable data is of invalid type')
    }

    if (overrides) {
      $.extend(conf, overrides)
    }

    if (conf && conf.layout && conf.layout.topEnd) {
      if (Array.isArray(conf.layout.topEnd)) {
        conf.layout.topEnd.push({ fullscreen: { checked: this.isFullScreen, onToggle: (ev) => this.toggleFullScreenMode(ev) } })
      }
    } else if (this.forceButtons) {
      conf.layout = conf.layout || {};
      conf.layout.topEnd = conf.layout.topEnd || [];
      conf.layout.topEnd.push({ fullscreen: { checked: this.isFullScreen, onToggle: (ev) => this.toggleFullScreenMode(ev) } });
    }

    if ("columns" in conf || conf.columns) {
      conf.columns.forEach((column) => {
        column.orderable = column.orderable === 1
      });
    }

    if (conf.serverSide) {
      conf.columns.forEach((column) => {
        column.render = (_data, type, row, meta) => this.renderData(type, row, meta)
      })

    }

    const self = this;

    conf.initComplete = async function () {
      self.hasSearch = self.hasSearch || !self.el.hasClass('datatables-no-header-search')
      if (self.el.hasClass('table-account-requests')) return;
      if (!conf.serverSide) return;
      const api = this.api();
      const columns = api.columns();
      if (self.initializingTable || conf.reinitialize) {
        columns.every(async function () {
          const column = this;
          if ($(column.header()).hasClass('data-table__header--invisible')) return;
          const index = column.index();
          const $header = $(column.header());
          const title = $header.text().trim();
          const searchValue = column.search();
          const col = self.columns[index];
          const id = isNaN(col.name) ? 0 : parseInt(col.name);

          const { context } = column;
          const { oAjaxData } = context[0];
          const { columns } = oAjaxData;
          const columnId = columns[column.index()].name;

          const $searchElement = $(`
          <div class="data-table__header">
            ${self.hasSearch ? `<div class="data-table__search">
              <button 
                  class="btn btn-search dropdown-toggle${searchValue ? ' active': ''}"
                  id="search-toggle-${index}"
                  type="button"
                  data-bs-toggle="dropdown"
                  aria-expanded="false"
                  data-boundary="viewport"
                  data-reference="parent"
                  data-bs-target="[data-ddl='ddl-index-${index}']"
                  data-focus="data-ddl='ddl-index-${index}'">
                  <span class="visually-hidden">Search in ${title}</span>
              </button>
              <div class="dropdown-menu p2" aria-labelledby="search-toggle-1">
                  <div class="input"></div>
                  <button type='button' class='btn btn-link btn-small data-table__clear hidden'>
                      <span>Clear filter</span>
                  </button>
              </div>
          </div>` :``}
          <div class="data-table__title">
            <span class="dt-column-title">${title}</div>
            <div class="data-table__sort"></div>
          </div>
        </div>
        `)

        if(self.hasSearch) {
          const $searchInput = $(`<input class='form-control form-control-sm' type='search' placeholder='Search' ${searchValue ? 'value="' + searchValue + '"' : ''}/>`)
          $searchInput.appendTo($('.input', $searchElement))
          if (col.typeahead_use_id) {
            $searchInput.after(`<input type="hidden" class="search">`)
            if (searchValue) {
              const response = await fetch(this.getApiEndpoint(columnId) + searchValue + '&use_id=1')
              const data = await response.json()
              if (!data.error) {
                if (data.records.length != 0) {
                  $searchInput.val(data.records[0].label)
                  $('input.search', $searchElement).val(data.records[0].id).trigger('change')
                }
              }
            }
          } else {
            $('input', $searchElement).addClass('search')
          }

          $('input.search', $searchElement).on('change clear', function (ev) {
            let value = this.value || ev.target.value;
            if (column.search !== value) {
              column.search(value).draw();
            }

            self.searchParams.has(id) ? this.value ? self.searchParams.set(id, this.value) : self.searchParams.delete(id) : self.searchParams.append(id, this.value);

            const searchParams = self.searchParams?.length ? '' : `?${self.searchParams.toString()}`
            const url = searchParams || searchParams.length > 1 ? `${window.location.href.split("?")[0]}${searchParams}` : window.location.href.split("?")[0];
            window.history.replaceState(null, '', url);

            if (isNotEmptyString(value)) {
              $header.find('.btn-search').addClass('active');
            } else {
              $header.find('.btn-search').removeClass('active');
            }
          });
        }

          column.header().replaceChildren($searchElement[0]);

          self.hasSearch && self.toggleFilter(column);

          if (col && col.typeahead) {
            import(/*webpackChunkName: "typeahead" */ "util/typeahead")
              .then(({ default: TypeaheadBuilder }) => {
                const builder = new TypeaheadBuilder();
                builder
                  .withAjaxSource(self.getApiEndpoint(columnId))
                  .withInput($('input', $header))
                  .withAppendQuery()
                  .withDefaultMapper()
                  .withName(columnId.replace(/\s+/g, '') + 'Search')
                  .withCallback((data) => {
                    if (col.typeahead_use_id) {
                      $searchInput.val(data.name);
                      $('input.search', $searchElement).val(data.id).trigger('change');
                    } else {
                      $('input', $searchElement).addClass('search').val(data.name).trigger('change');
                    }
                  })
                  .build();
              });
          }

          if (self.hasSearch && $header.hasClass('dt-orderable-asc') || $header.hasClass('dt-orderable-desc')) {
            $header.find('.data-table__search').on('click', (ev) => {
              ev.stopPropagation();
            });
          }
        });

        this.initializingTable && initializeRegisteredComponents(self.element);

        this.initializingTable = false;
      }
    }

    conf.footerCallback = function () {
      const api = this.api();
      // Add aggregate values to table if configured
      const agg = api.ajax && api.ajax.json() && api.ajax.json().aggregate;
      if (agg) {
        const cols = api.settings()[0].oAjaxData.columns;
        api.columns().every(function () {
          const idx = this.index()
          const { name } = cols[idx]
          if (agg[name]) {
            $(this.footer()).html(
              self.renderDataType(agg[name])
            )
          }
          return true;
        })
      }
    }

    conf.drawCallback = () => {

      //Re-initialize more-less components after initialisation is complete
      moreLess.reinitialize()

      // (Re)enable wide-table toggle button each time. It is disabled during
      // any drawing to prevent it being clicked multiple times during a draw

      this.bindClickHandlersAfterDraw(conf);
    }

    return conf
  }

  /**
   * Toggle fullscreen mode
   * @param {JQuery.Event} ev The button element
   */
  toggleFullScreenMode(ev) {
    const table = $("table.data-table");
    if (!this.isFullScreen) {
      this.isFullScreen = true;
      // Create new modal
      const newModal = createElement('div',
        {
          id: "table-modal",
          classList: ['table-modal', 'data-table__container--scrollable']
        });

      // Move data table into new modal
      if ($.fn.dataTable.isDataTable(table)) table.DataTable().destroy()
      const newTable = table.clone(false, false);
      newTable.attr('id', '#fullScreenTable')
      newModal.append(newTable);
      $('body').append(newModal);
      if (newTable && !$.fn.dataTable.isDataTable(newTable)) {
        $(newTable).DataTable(this.getConf({ responsive: false }));
      }

      $(document).on("keyup", (ev) => {
        if (ev.key === "Escape") {
          this.toggleFullScreenMode(ev);
        }
      });
      $(ev.target).attr('checked', 'checked');
    } else {
      this.isFullScreen = false;
      // Remove the modal
      document.querySelector('#table-modal').remove();

      $('#fullScreenTable').DataTable().destroy();
      let dataTable = $('table.data-table');
      $.fn.dataTable.isDataTable('table.data-table') && dataTable.DataTable().destroy();
      dataTable.DataTable(this.getConf({ reinitialize: true }));

      $(document).off("keyup");
      $(ev.target).removeAttr('checked');
    }
  }

  /**
   * Bind any click handlers once the Datatable is rendered
   * @param {{serverSide: boolean}} conf The datatable configuration
   */
  bindClickHandlersAfterDraw(conf) {
    function findResult(data) {
      if (!data || !Array.isArray(data)) throw new Error("Invalid data");
      return data.find((item) => item.match(/^<a href="(\/.*?\/record\/\d+)">/gm)).match(/href="(.*?)"/)[1];
    }

    const tableElement = this.el
    const rows = tableElement.DataTable().rows({ page: 'current' }).data()

    if (rows && this.base_url) {
      // Add click handler to tr to open a record by id
      $(tableElement).find('> tbody > tr').each((i, el) => {
        const data = rows[i]
        if (data) {
          // URL will be record link for standard view, or filtered URL for
          // grouped view (in which case _count parameter will be present not _id)
          let url = '';
          try {
            url = Array.isArray(data) ? findResult(data) : data['_id'] ? `${this.base_url}/${data['_id']}` : `?${data['_count']['url']}`
            if (!url) {
              throw new Error("No URL found");
            }
          } catch (e) {
            console.warn("No ID found", e)
          }

          $(el).find('td:not(.dtr-control)').on('click', (ev) => {
            // Only for table cells that are not part of a record-popup table row
            if (!ev.target.closest('.record-popup')) {
              window.location = url
            }
          })
        }
      })
    }

    if (conf.serverSide) {
      // Add click handler to disclosure widgets that are not part of a more-less component
      const $disclosureWidgets = $(tableElement).find(':not(.more-less) > .trigger[aria-expanded]')

      // First, remove all existing click events to prevent multiple bindings
      $disclosureWidgets.off('click', onDisclosureClick)
      $disclosureWidgets.on('click', onDisclosureClick)

      initializeRegisteredComponents(this.element)
    }
  }
}

export default DataTableComponent
