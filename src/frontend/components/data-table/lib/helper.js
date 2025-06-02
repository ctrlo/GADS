import "datatables.net-bs5"

/**
 * Add a row to the table
 * @param {*} rowData The data to add the row to
 * @param {*} table The table to add the row to
 */
const addRow = (rowData, table) => {
  // Insert row at bottom of table
  table.DataTable().row.add(rowData).draw()
}

/**
 * Update a row in the table
 * @param {*} rowData The row data to update
 * @param {*} table The table to update the row in
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
 * Clear a table
 * @param {*} table The table to clear
 */
const clearTable = (table) => {
  table.DataTable().clear().draw()
}

/**
 * Get the row order
 * @param {*} row The row in the table
 * @returns An integer value of the order of the row
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
