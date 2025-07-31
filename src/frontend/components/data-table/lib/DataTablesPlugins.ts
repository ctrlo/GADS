import DataTable from 'datatables.net-bs4';

/**
 * Create a toggle button
 * @param id The id of the toggle button
 * @param label The label to use for the toggle button
 * @param onToggle The function to call when the toggle button is toggled
 * @returns A jQuery object representing the toggle button
 */
function createToggleButton(id:string, label:string, checked: boolean, onToggle:(ev:JQuery.Event)=>void) {
    const element = $(`
    <div class="dt-toggle-button">
        <div class="custom-control custom-switch">
            <input class="custom-control-input" type="checkbox" role="switch" id="${id}" ${checked ? 'checked' : ''}>
            <label class="custom-control-label" for="${id}">${label}</label>
        </div>
    </div>`);

    element.find(`#${id}`).on('change', (ev) => {
        const target = ev.target as HTMLInputElement;
        target.checked = !target.checked;
        onToggle(ev);
    });

    return element;
}

// I feel using the "proper" toggle from bootstrap is better than the custom one and adding extra "fluff" to the datatables code in my opinion
DataTable.feature.register('fullscreen', function (settings, opts) {
    return createToggleButton('fullscreen-button', 'Fullscreen', opts.checked, opts.onToggle);
});
