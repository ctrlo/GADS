/**
 * Add all fields from source table to destination table
 * @param element {JQuery<HTMLElement>} - The button element
 */
export default function createAddAllFieldsButton(element: JQuery<HTMLElement>) {
    element.on('click', (ev) => {
        ev.preventDefault()
        const sourceTableId = $(ev.target).data('transferSource')
        const destinationTableId = $(ev.target).data('transferDestination')
        const rows = $(sourceTableId).find('tbody tr')
        import(/* webpackChunkName: "datatable-helper" */ '../../data-table/lib/helper')
            .then(({transferRowToTable}) => {
                rows.each((index, row) => {
                    transferRowToTable($(row), sourceTableId, destinationTableId)
                });
            });
    });
}
