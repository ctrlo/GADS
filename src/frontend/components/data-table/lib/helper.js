/**
 * Add a row at the bottom of a table
 * @param {*} rowData The data for the row to add
 * @param {*} table The datatable to add the row to
 */
const addRow = (rowData, table) => {
  table.DataTable().row.add(rowData).draw()
}

/**
 * Update a row in a table
 * @param {*} rowData The data to update
 * @param {*} table The table to update the data in
 * @param {*} id The ID of the row to update
 */
const updateRow = (rowData, table, id) => {
  const rows = table.find('tbody > tr')
  rows.each((i, row) => {
    if ($(row).has(`button[data-tempid=${id}]`).length) {
      table.DataTable().row(i).data(rowData).draw()
    }
  })
}

/**
 * Clear a table of all data
 * @param {*} table The table to clear
 */
const clearTable = (table) => {
  table.DataTable().clear().draw()
}

/**
 * Get the row order from a row
 * @param {*} row The row to get the order from
 */
const getRowOrder = (row) => {
  try {
    const orderValue = $(row.node()).find('input').first().data('order')
    if (typeof orderValue === "undefined") {
      return -1
    }
    return parseInt(orderValue)
  } catch {
    return -1
  }
}

export { addRow, updateRow, clearTable, getRowOrder }
