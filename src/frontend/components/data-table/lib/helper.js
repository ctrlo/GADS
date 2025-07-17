const addRow = (rowData, table) => {
    // Insert row at bottom of table
    table.DataTable().row.add(rowData).draw();
};

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

const clearTable = (table) => {
    table.DataTable().clear()
        .draw();
};

const getRowOrder = (row) => {
    try {
        const orderValue = $(row.node()).find('input')
            .first()
            .data('order');
        if (typeof orderValue === 'undefined') {
            return -1;
        }
        return parseInt(orderValue);
    } catch {
        return -1;
    }
};

export { addRow, updateRow, clearTable, getRowOrder };
