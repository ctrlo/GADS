/**
 * Add a new row to the table.
 * @param {object} rowData The row data to be added to the table.
 * @param {JQuery} table The jQuery element of the table to which the row will be added.
 */
const addRow = (rowData, table) => {
    // Insert row at bottom of table
    table.DataTable().row.add(rowData).draw();
};

/**
 * Update an existing row in the table.
 * @param {object} rowData The updated row data.
 * @param {JQuery} table The table to update.
 * @param {string} id The ID of the row to update.
 */
const updateRow = (rowData, table, id) => {
    const rows = table.find('tbody > tr');
    rows.each((i, row) => {
        if ($(row).has(`button[data-tempid=${id}]`).length) {
            table.DataTable().row(i)
                .data(rowData)
                .draw();
        }
    });
};

/**
 * Clear all rows from the table.
 * @param {JQuery} table The jQuery element of the table to clear.
 */
const clearTable = (table) => {
    table.DataTable().clear()
        .draw();
};

export { addRow, updateRow, clearTable };
