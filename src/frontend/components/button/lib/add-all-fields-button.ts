/**
 * Add all fields from source table to destination table
 * @param element {JQuery<HTMLElement>} - The button element
 */
export default function createAddAllFieldsButton(element: JQuery<HTMLElement>) {
    element.on('click', (ev) => {
        ev.preventDefault()
        const sourceTableId = $(ev.target).data('toggleSource')
        const clickedSourceTable = document.querySelector(sourceTableId)
        const destinationTableID = $(ev.target).data('toggleDestination')
        const rows = $(sourceTableId).find('tbody tr')
        import(/* webpackChunkName: "datatable-toggle-table" */ '../../data-table/lib/toggle-table')
            .then(({toggleRowInTable}) => {
                rows.each((index, row) => {
                    toggleRowInTable(<HTMLTableRowElement> row, clickedSourceTable, destinationTableID, true)
                });
            });
    });
}
