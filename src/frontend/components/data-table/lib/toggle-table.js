/* Explanation of the Toggle Table:
  A toggle table consist of two twin tables containing the same fields
  One table contains hidden checkboxes while the other one contains text only
  This is used to "move" fields between the tables (using display: none; for unchecked fields)
*/

const bindToggleTableClickHandlers = (tableElement) => {
    if (tableElement.hasClass('table-toggle')) {
        const fields = tableElement.find('tbody tr');
        fields.off('click', toggleRow);
        fields.on('click', toggleRow);

        const buttons = tableElement.find('tbody btn');
        buttons.off('click', toggleRow);
        buttons.on('click', toggleRow);
    }
};

const toggleRow = (ev) => {
    ev.preventDefault();
    const clickedRow = $(ev.target).closest('tr')[0];
    const clickedSourceTable = $(ev.target).closest('table');
    const destinationTableID = clickedSourceTable.data('destination');

    toggleRowInTable(clickedRow, clickedSourceTable, destinationTableID);
};

/**
 * Toggles (switches) all fields from source table to destination table
 * @param {HTMLTableRowElement} clickedRow The row element to toggle
 * @param {HTMLTableElement} sourceTable The table of the clicked row (source)
 * @param {string} destinationTableID ID of the table where it's twin field need to be toggled
 * @param {boolean | null} forceCheck When defined it will force the field be checked (true) or unchecked (false).
 *                                    Default = null, meaning it will toggle based on its currect check status)
 */
const toggleRowInTable = (clickedRow, sourceTable, destinationTableID, forceCheck = null) => {
    // Retrieve the destination table
    const destinationTable = $(destinationTableID);
    if (typeof destinationTable == 'undefined') {
        console.error(`Failed to toggle row; missing 'toggle-destination' data attribute for table '${sourceTable.attr('id')}'`);
        return;
    }

    // Get the destination row (to be toggled)
    const toggleFieldID = clickedRow.dataset.toggleFieldIdSelector + clickedRow.dataset.toggleFieldId;
    const destinationRow = destinationTable.DataTable().row(toggleFieldID);

    if (destinationRow.length == 0) {
        console.error(`Failed to toggle row; missing row ${toggleFieldID} in table ${destinationTableID}`);
        return;
    }

    // Toggle checkbox in source table
    const sourceRowCheckbox = clickedRow.querySelector('input');
    if (sourceRowCheckbox) {

        if (typeof forceCheck == 'boolean') {
            // Set the checkbox
            sourceRowCheckbox.checked = !forceCheck;
        } else {
            // Toggle the checkbox
            sourceRowCheckbox.checked ^= 1;
        }
    }

    // Change the checkbox in destination table
    const destinationRowCheckbox = destinationRow.node().querySelector('input');
    if (destinationRowCheckbox) {
        if (typeof forceCheck == 'boolean') {
            // Set the checkbox
            destinationRowCheckbox.checked = forceCheck;
        } else {
            // Toggle the checkbox
            destinationRowCheckbox.checked ^= 1;
        }
    }

    // Change data-field-is-toggled in destination table
    const destinationRowDataAttribute = destinationRow.node().dataset.fieldIsToggled;
    if (destinationRowDataAttribute) {
        if (typeof forceCheck == 'boolean') {
            // Set the attribute
            destinationRow.node().dataset.fieldIsToggled = forceCheck.toString();
        } else {
            // Toggle the attribute
            destinationRow.node().dataset.fieldIsToggled = destinationRowDataAttribute == 'true' ? 'false' : 'true';
        }

    }

    // Toggle data-field-is-toggled in source table
    const sourceRowDataAttribute = clickedRow.dataset.fieldIsToggled;
    if (typeof sourceRowDataAttribute != 'undefined') {
        if (typeof forceCheck == 'boolean') {
            // Set the attribute
            clickedRow.dataset.fieldIsToggled = !forceCheck.toString();
        } else {
            // Toggle the attribute
            clickedRow.dataset.fieldIsToggled = sourceRowDataAttribute == 'true' ? 'false' : 'true';
        }
    }
};

export { bindToggleTableClickHandlers, toggleRow, toggleRowInTable };
