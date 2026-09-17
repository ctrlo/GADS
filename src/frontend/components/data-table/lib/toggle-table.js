import { logging } from "logging";
/**
  * @fileoverview A toggle table consist of two twin tables containing the same fields
  * One table contains hidden checkboxes while the other one contains text only
  * This is used to "move" fields between the tables (using display: none; for unchecked fields)
*/

/**
 * Bind click handlers to toggle table rows.
 * @param {JQuery} tableElement The jQuery element of the table to bind click handlers to.
 */
const bindToggleTableClickHandlers = (tableElement) => {
    if (tableElement.hasClass("table-toggle")) {
        const fields = tableElement.find("tbody tr");
        fields.off("click", toggleRow);
        fields.on("click", toggleRow);

        const buttons = tableElement.find("tbody btn");
        buttons.off("click", toggleRow);
        buttons.on("click", toggleRow);
    }
};

/**
 * Toggle a row in the table when clicked.
 * @param {JQuery.ClickEvent} ev The click event triggered by the user.
 */
const toggleRow = (ev) => {
    ev.preventDefault();
    const clickedRow = $(ev.target).closest("tr")[0];
    const clickedSourceTable = $(ev.target).closest("table");
    const destinationTableID = clickedSourceTable.data("destination");

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
    const coerceInvert = (value) => typeof value == "boolean" ? !value : !!(value ^ 1);

    const destinationTable = $(destinationTableID);
    if (destinationTable.length == 0) {
        logging.error(`Failed to toggle row; missing 'toggle-destination' data attribute for table '${sourceTable.attr("id")}'`);
        return;
    }

    // Get the destination row (to be toggled)
    const toggleFieldID = clickedRow.dataset.toggleFieldIdSelector + clickedRow.dataset.toggleFieldId;
    const destinationRow = destinationTable.DataTable().row(toggleFieldID);

    if (destinationRow.length == 0) {
        logging.error(`Failed to toggle row; missing row ${toggleFieldID} in table ${destinationTableID}`);
        return;
    }

    // Toggle checkbox in source table
    const sourceRowCheckbox = clickedRow.querySelector("input");
    if (sourceRowCheckbox) sourceRowCheckbox.checked = coerceInvert(forceCheck);

    // Change the checkbox in destination table
    const destinationRowCheckbox = destinationRow.node().querySelector("input");
    if (destinationRowCheckbox) destinationRowCheckbox.checked = coerceInvert(forceCheck);

    // Change data-field-is-toggled in destination table
    const destinationRowDataAttribute = destinationRow.node().dataset.fieldIsToggled;
    if (destinationRowDataAttribute) {
        destinationRow.node().dataset.fieldIsToggled = coerceInvert(forceCheck).toString();
    }

    // Toggle data-field-is-toggled in source table
    const sourceRowDataAttribute = clickedRow.dataset.fieldIsToggled;
    if (typeof sourceRowDataAttribute != "undefined") {
        clickedRow.dataset.fieldIsToggled = coerceInvert(forceCheck).toString();
    }
};

export { bindToggleTableClickHandlers, toggleRowInTable };
