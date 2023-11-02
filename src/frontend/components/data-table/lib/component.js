import { initializeRegisteredComponents, Component } from 'component'
import 'datatables.net'
import 'datatables.net-buttons'
import 'datatables.net-bs4'
import 'datatables.net-responsive'
import 'datatables.net-responsive-bs4'
import 'datatables.net-rowreorder-bs4'
import { setupDisclosureWidgets, onDisclosureClick } from '../../more-less/lib/disclosure-widgets'
import RecordPopupComponent from '../../record-popup/lib/component'
import { moreLess } from '../../more-less/lib/more-less'
import { Buffer } from 'buffer'

const MORE_LESS_TRESHOLD = 50

class DataTableComponent extends Component {
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.hasCheckboxes = this.el.hasClass('table-selectable')
    this.hasClearState = this.el.hasClass('table-clear-state')
    this.searchParams = new URLSearchParams(window.location.search)
    this.base_url = this.el.data('href') ? this.el.data('href') : undefined
    this.initTable()
  }

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
    this.el.DataTable(conf)
    this.initializingTable = true

    if (this.hasCheckboxes) {
      this.addSelectAllCheckbox()
    }
    if (this.el.hasClass('table-account-requests')) {
      this.modal = $.find('#userModal')
      this.initClickableTable()
    }

    // Bind events to disclosure buttons and record-popup links on opening of child row
    $(this.el).on('childRow.dt', (e, show, row) => {
      const $childRow = $(row.child())
      const recordPopupElements = $childRow.find('.record-popup')

      setupDisclosureWidgets($childRow)

      recordPopupElements.each((i, el) => {
        new RecordPopupComponent(el)
      })
    })

    $(document).on('fullscreenchange', (e) => {
      if (!document.fullscreenElement) {
        this.exitFullScreenMode(conf)
      } else {
        this.enterFullScreenMode(conf)
      }
    })
  }

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

      if (window.location.href.indexOf(`/${keySegments.slice(1).join('/')}`) !== -1) {
        localStorage.removeItem(storageKey)
      }
    }
  }

  initClickableTable() {
    const links = this.el.find('tbody td .link')
    links.on('click', (ev) => { this.handleClick(ev) })
    links.on('focus', (ev) => { this.toggleFocus(ev, true) })
    links.on('blur', (ev) => { this.toggleFocus(ev, false) })
  }

  toggleFocus(ev, hasFocus) {
    const row = $(ev.target).closest('tr')
    if (hasFocus) {
      row.addClass('tr--focus')
    } else {
      row.removeClass('tr--focus')
    }
  }

  handleClick(ev) {
    const rowClicked = $(ev.target).closest('tr')
    ev.preventDefault()
    this.fillModalData(rowClicked)
    $(this.modal).modal('show')
  }

  fillModalData(row) {
    const fields = $(this.modal).find('input')
    const btnReject = $(this.modal).find('.btn-js-reject-request')
    const id = parseInt($(row).find(`td[data-id]`).data('id'), 10)

    if (id) $(this.modal).data('config').id = id

    if (btnReject && id && (!isNaN(id))) {
      btnReject.val(id)
    }

    fields.each((i, field) => {
      const fieldName = $(field).attr('name')
      const fieldValue = $(row).find(`td[data-${fieldName}]`).data(fieldName)

      if (fieldValue) {
        $(field).val(fieldValue)
        $(field).data('original-value', fieldValue)
        $(field).trigger('change')
      }
    })
  }

  getCheckboxElement(id, label) {
    return (
      `<div class='checkbox'>` +
      `<input id='dt_checkbox_${id}' type='checkbox' />` +
      `<label for='dt_checkbox_${id}'><span>${label}</span></label>` +
      '</div>'
    )
  }

  addSelectAllCheckbox() {
    const $selectAllElm = this.el.find('thead th.check')
    const $checkBoxes = this.el.find('tbody .check .checkbox input')

    if ($selectAllElm.length) {
      $selectAllElm.html(this.getCheckboxElement('all', 'Select all'))
    }

    // Check if all checkboxes are checked and the 'select all' checkbox needs to be checked
    this.checkSelectAll($checkBoxes, $selectAllElm.find('input'))

    $checkBoxes.on('click', (ev) => {
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

  checkAllCheckboxes($checkBoxes, bCheckAll) {
    if (bCheckAll) {
      $checkBoxes.prop('checked', true)
    } else {
      $checkBoxes.prop('checked', false)
    }
  }

  checkSelectAll($checkBoxes, $selectAllCheckBox) {
    let bSelectAll = true

    $checkBoxes.each((i, checkBox) => {
      if (!checkBox.checked) {
        $selectAllCheckBox.prop('checked', false)
        bSelectAll = false
      }
    })

    if (bSelectAll) {
      $selectAllCheckBox.prop('checked', true)
    }
  }

  addSortButton(dataTable, column) {
    const $header = $(column.header())
    const $button = $(`
      <button class="data-table__sort" type="button">
        <span>${$header.html()}</span>
        <span class="btn btn-sort">
          <span>Sort</span>
        </span>
      </button>`
    )

    $header
      .off()
      .find('.data-table__header-wrapper').html($button)

    dataTable.order.listener($button, column.index())
  }

  toggleFilter(column) {
    const $header = $(column.header())

    if (column.search() !== '') {
      $header.find('.data-table__header-wrapper').addClass('filter')
      $header.find('.data-table__clear').show()
    } else {
      $header.find('.data-table__header-wrapper').removeClass('filter')
      $header.find('.data-table__clear').hide()
    }
  }

  addSearchDropdown(column, id, index) {
    const $header = $(column.header())
    const title = $header.text().trim()
    const searchValue = column.search()
    const self = this

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
              <input class='form-control form-control-sm field-search-${index}' type='text' placeholder='Search' value='${searchValue}'/>
            </div>
          </label>
          <div class='data-table__live-search'>
            <ul class='data-list list-unstyled text-center'></ul>        
          </div>
          <button type='button' class='btn btn-link btn-small data-table__clear hidden'>
            <span>Clear filter</span>
          </button>
        </div>
      </div>`
    )

    $header.find('.data-table__header-wrapper').prepend($searchElement)

    this.toggleFilter(column)

    const columnData = {
      header: column.header(),
      data: column.nodes().map((cell) => $(cell).text().toLowerCase())
    }

    if(this.checkForColumnData(columnData)) {
      this.addColumnData(columnData);
    }

    $('input', $header).on('keyup', function () {
      const $list=$('.data-list');
      if (this.value.length < 1) {
        $list.empty();
        return;
      }
      const data = [];
      column.nodes().each((cell, i) => {
        const myData = $(cell).text().toLowerCase();
        const addition={}
        addition.data=myData;
        addition.id=i;
        if (myData.includes(this.value.toLowerCase())) data.push(addition);
      });
      $list.empty();
      $list.append(data.map((item) => `<li><button class='btn-link' data-id='${item.id}' data-search='${item.data}'>${item.data}</button></li>`).join(''));
      const $btn = $list.find('button');
      $btn.on('click', function () {
        $list.empty();
        const searchString = $(this).data('search');
        column.search(searchString).draw();
      });
    });

    // Apply the search
    $('input', $header).on('change', function () {
      if (column.search() !== this.value) {
        column
          .search(this.value)
          .draw()
      }

      self.toggleFilter(column)

      // Update or add the filter to the searchParams
      self.searchParams.has(id) ?
        self.searchParams.set(id, this.value) :
        self.searchParams.append(id, this.value)

      // Update URL. Do not reload otherwise the data is fetched twice (already
      // redrawn in the previous statement)
      const url = `${window.location.href.split('?')[0]}?${self.searchParams.toString()}`
      window.history.replaceState(null, '', url);
    })

    // Clear the search
    $('.data-table__clear', $header).on('click', function () {
      $(this).closest('.dropdown-menu').find('input').val('')
      column
        .search('')
        .draw()

      self.toggleFilter(column)

      // Delete the filter from the searchparams and update and reload the url
      if (self.searchParams.has(id)) {
        self.searchParams.delete(id)
        let url = `${window.location.href.split('?')[0]}`

        if (self.searchParams.entries().next().value !== undefined) {
          url += `?${self.searchParams.toString()}`
        }

        // Update URL. See comment above about the same
        window.history.replaceState(null, '', url);
      }
    })
  }

  encodeHTMLEntities(text) {
    return $("<textarea/>").text(text).html();
  }

  decodeHTMLEntities(text) {
    return $("<textarea/>").html(text).text();
  }

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

  renderId(data) {
    let retval = ''
    const id = data.values[0]
    if (!id) return retval
    if (data.parent_id) {
      retval = `<span title="Child record with parent record ${data.parent_id}">${data.parent_id} &#8594;</span> `
    }
    return `${retval}<a href="${this.base_url}/${id}">${id}</a>`
  }

  renderPerson(data) {
    let strHTML = ''

    if (!data.values.length) {
      return strHTML
    }

    const value = data.values[0] // There's always only one person

    data.values.forEach((value, i) => {
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
            <button class="btn btn-small btn-inverted btn-info trigger" aria-expanded="false" type="button">
              ${this.encodeHTMLEntities(value.text)}
              <span class="invisible">contact details</span>
            </button>
            <div class="person contact-details expandable popover card card--secundary">
              ${thisHTML}
            </div>
          </div>`
        )
      }
    })

    return strHTML
  }

  renderFile(data) {
    let strHTML = ''

    if (!data.values.length) {
      return strHTML
    }

    data.values.forEach((file) => {
      strHTML += `<a href="/file/${file.id}">`
      if (file.mimetype.match('^image/')) {
        strHTML += `<img class="autosize" src="/file/${file.id}"></img>`
      } else {
        strHTML += `${this.encodeHTMLEntities(file.name)}<br>`
      }
      strHTML += `</a>`
    })

    return strHTML
  }

  renderRag(data) {
    let strRagType = ''
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

    const text = $(`#rag_${strRagType}_meaning`).text();

    return `<span class="rag rag--${strRagType}" title="${text}" aria-labelledby="rag_${strRagType}_meaning"><span>✗</span></span>`
  }

  renderCurCommon(data) {
    let strHTML = ''

    if (data.values.length === 0) {
      return strHTML
    }

    strHTML = this.renderCurCommonTable(data)
    return this.renderMoreLess(strHTML, data.name)
  }

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

  renderDataType(data) {
    switch (data.type) {
      case 'id':
        return this.renderId(data)
      case 'person':
      case 'createdby':
        return this.renderPerson(data)
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

  renderData(type, row, meta) {
    const strColumnName = meta ? meta.settings.oAjaxData.columns[meta.col].name : ""
    const data = row[strColumnName]

    if (typeof data !== 'object') {
      return ''
    }

    return this.renderDataType(data)
  }

  getConf() {
    const confData = this.el.data('config')
    let conf = {}
    const self = this

    if (typeof confData === 'string') {
      conf = JSON.parse(Buffer.from(confData, 'base64'))
    } else if (typeof confData === 'object') {
      conf = confData
    }

    if (conf.serverSide) {
      conf.columns.forEach((column) => {
        column.render = (data, type, row, meta) => this.renderData(type, row, meta)
      })
    }

    conf['initComplete'] = (settings, json) => {
      const tableElement = this.el
      const dataTable = tableElement.DataTable()
      const self = this

      this.json = json ? json : undefined
      
      if (this.initializingTable) {
        dataTable.columns().every(function(index) {
          const column = this
          const $header = $(column.header())

          const headerContent = $header.html()
          $header.html(`<div class='data-table__header-wrapper position-relative ${column.search() ? 'filter' : ''}' data-ddl='ddl_${index}'>${headerContent}</div>`)

          // Add sort button to column header
          if ($header.hasClass('sorting')) {
            self.addSortButton(dataTable, column, headerContent)
          }

          // Add button to column headers (only serverside tables)
          if ((conf.serverSide) && (tableElement.hasClass('table-search'))) {
            const id = settings.oAjaxData.columns[index].name

            if (self.searchParams.has(id)) {
              column.search(self.searchParams.get(id)).draw()
            }

            self.addSearchDropdown(column, id, index)
          } 
        })

        // If the table has not wrapped (become responsive) then hide the toggle button
        if (!this.el.hasClass("collapsed")) {
          if (this.el.closest('.dataTables_wrapper').find('.btn-toggle-off').length) {
            this.el.closest('.dataTables_wrapper').find('.dataTables_toggle_full_width').hide()
          }
        } 

        this.initializingTable = false
      }
    }

    conf['footerCallback'] = function (tfoot, data, start, end, display) {
      const api = this.api()
      // Add aggregate values to table if configured
      const agg = api.ajax && api.ajax.json() && api.ajax.json().aggregate
      if (agg) {
        const cols = api.settings()[0].oAjaxData.columns
        api.columns().every(function () {
          const idx = this.index()
          const { name } = cols[idx]
          if (agg[name]) {
            $(this.footer()).html(
              self.renderDataType(agg[name])
            )
          }
        })
      }
    }

    conf['drawCallback'] = (settings) => {

      //Re-initialize more-less components after initialisation is complete
      moreLess.reinitialize()

      // (Re)enable wide-table toggle button each time. It is disabled during
      // any drawing to prevent it being clicked multiple times during a draw
      this.el.DataTable().button(0).enable();

      this.bindClickHandlersAfterDraw(conf)

      if (document.fullscreenElement) {
        this.setFullscreenTableContainerHeight()
      }
    }

    conf['buttons'] = [
      {
        text: 'Full screen',
        enabled: false,
        className: 'btn btn-small btn-toggle-off',
        action: function ( e, dt, node, config ) {
          if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen()
          } else {
            document.exitFullscreen()
          }
        }
      }
    ]

    return conf
  }

  enterFullScreenMode(conf) {
    this.originalResponsiveObj = conf.responsive
    conf.responsive = false
    this.el.DataTable().destroy();
    this.el.removeClass('dtr-column collapsed');
    this.el.DataTable(conf)
    this.initializingTable = true
    const $dataTableContainer = this.el.parent()

    $dataTableContainer.addClass('data-table__container--scrollable')
    // // See comments above regarding preventing multiple clicks
    this.el.DataTable().button(0).disable();
    this.el.closest('.dataTables_wrapper').find('.btn-toggle-off').toggleClass(['btn-toggle', 'btn-toggle-off'])
  }

  exitFullScreenMode(conf) {
    conf.responsive = this.originalResponsiveObj
    this.el.DataTable().destroy();
    this.el.DataTable(conf)
    this.initializingTable = true
    // See comments above regarding preventing multiple clicks
    this.el.DataTable().button(0).disable();
  }

  setFullscreenTableContainerHeight() {
    const $dataTableContainer = this.el.parent()
    const $dataTableWrapper = $dataTableContainer.closest('.dataTables_wrapper')
    const tableWrapperHeight = $dataTableWrapper.innerHeight()
    const tableHeaderHeight = $dataTableWrapper.find('.row--header') ? $dataTableWrapper.find('.row--header').innerHeight() : 0
    const tableFooterHeight = $dataTableWrapper.find('.row--footer') ? $dataTableWrapper.find('.row--footer').innerHeight() : 0
    const viewportHeight = window.innerHeight
    const margins = 128

    if (tableWrapperHeight > viewportHeight) {
      $dataTableContainer.height(viewportHeight - tableHeaderHeight - tableFooterHeight - margins);
    }
  }

  bindClickHandlersAfterDraw(conf) {
    const tableElement = this.el
    const rows = tableElement.DataTable().rows({ page: 'current' }).data()

    if (rows && this.base_url) {
      // Add click handler to tr to open a record by id
      $(tableElement).find('> tbody > tr').each((i, el) => {
        const data = rows[i] ? rows[i] : undefined
        if (data) {
          // URL will be record link for standard view, or filtered URL for
          // grouped view (in which case _count parameter will be present not _id)
          const url = data['_id'] ? `${this.base_url}/${data['_id']}` : `?${data['_count']['url']}`

          $(el).find('td:not(".dtr-control")').on('click', (ev) => {
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

  /**
   * Check for column data in allData
   * @param {{header: string, data: string[]}} columnData data to check
   * @returns {boolean} true if columnData is not present in allData, false otherwise
   */
  checkForColumnData(columnData) {
    //Null reference checks - better to be safe!
    this.allData = this.allData || [];
    this.allData.forEach((data) => {
      if(data.header === columnData.header) {
        return false;
      }
    });
    return true;
  }

  /**
   * Add a column to the database
   * @param {{header: string, data:string[]}} columnData data to check
   */
  addColumnData(columnData) {
    //Null reference checks - better to be safe!
    this.allData=this.allData || [];
    this.allData.push(columnData);
  }
}

export default DataTableComponent
