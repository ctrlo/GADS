import { BaseButton } from './base-button';

class ToggleAllFieldsButton extends BaseButton {
    type= 'btn-js-toggle-all-fields';
    
    click(ev: JQuery.ClickEvent): void {
        ev.preventDefault();
        const sourceTableId = $(ev.target).data('toggleSource');
        const clickedSourceTable = document.querySelector(sourceTableId);
        const destinationTableID = $(ev.target).data('toggleDestination');
        const rows = $(sourceTableId).find('tbody tr');
        import(/* webpackChunkName: "datatable-toggle-table" */ '../../data-table/lib/toggle-table')
            .then(({toggleRowInTable}) => {
                rows.each((index, row) => {
                    toggleRowInTable(<HTMLTableRowElement> row, clickedSourceTable, destinationTableID, true);
                });
            });
    }

}

export default function createToggleAllFieldsButton(element: JQuery<HTMLElement>) {
    return new ToggleAllFieldsButton(element);
}
