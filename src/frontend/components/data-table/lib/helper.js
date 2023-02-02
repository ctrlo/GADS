const addRow = (rowData, table) => {
  table.DataTable().row.add(rowData).draw()
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

export { addRow, updateRow, clearTable }
