const addRow = (rowData, table, keepOrder = false) => {
  if (!keepOrder) {
    // Insert row at bottom of table
    table.DataTable().row.add(rowData).draw()
  } else {
    addRowWithOrder(rowData, table)
  }
}

const updateRow = (rowData, table, id) => {
  const rows = table.find('tbody > tr')
  rows.each((i, row) => {
    if ($(row).has(`button[data-tempid=${id}]`).length) {
      table.DataTable().row(i).data(rowData).draw()
    }
  })
}

const clearTable = (table) => {
  table.DataTable().clear().draw()
}

// Reorder the table based on 'order' data attribute in the checkbox subfield in the row
const addRowWithOrder = (rowData, tableElement) => {
  const table = tableElement.DataTable();

  // Insert the row
  table.row.add(rowData).draw('page');

  // Move added row to desired index
  const rowCount = table.data().length-1
  let newRow = table.row(rowCount)
  const newRowOrder = getRowOrder(newRow)

  for (var i = rowCount; i > 0; i--) {
    // Get new row's current element and data
    newRow = table.row(i)
    const newRowData = newRow.data()

    // Get current row for comparison
    const nextRow = table.row(i-1)
    const nextRowOrder = getRowOrder(nextRow)

    // Stop reordering table if new row is in the right position
    if (nextRowOrder < newRowOrder) {
      break;
    }

    // Move new row up one position
    table.row(i).data(nextRow.data());
    table.row(i-1).data(newRowData);
  }

  // Refresh the current page
  table.page(table.page()).draw(false);
};

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

const transferRowToTable = (rowClicked, sourceTableID, destinationTableID) => {
  // Retrieve the source table
  if (typeof sourceTableID == "undefined") {
    console.error(`Failed to move row; missing sourceTableID`)
    return
  }
  const sourceTable = $(sourceTableID);

  // Retrieve the data from clicked row
  const inputElement = rowClicked.find('input').first()
  if (inputElement.length === 0) {
    console.error(`Failed to move row from table '${sourceTableID}'; missing checkbox input element`)
  }

  // Toggle the hidden checkbox
  inputElement.attr('checked', !inputElement.prop("checked"))

  // Retrieve the destination table
  if (typeof destinationTableID == "undefined") {
    console.error(`Failed to move row; missing 'transfer-destination' data attribute for table '${sourceTableID}'`)
    return
  }
  const destinationTable = $(destinationTableID)

  // Move the updated row to destination table
  const rowObject = sourceTable.DataTable().row(rowClicked)
  const rowHasOrder = getRowOrder(rowObject) > -1
  if (!rowHasOrder) {
    console.warn(`Failed to move row to correct position in '${destinationTableID}'; missing data-order attribute in checkbox input element`)
  }
  rowObject.invalidate()
  addRow(rowObject.data(), destinationTable, rowHasOrder)

  // Remove the row from source table
  rowObject.remove().draw('page')
}

export { addRow, updateRow, clearTable, getRowOrder, transferRowToTable }
