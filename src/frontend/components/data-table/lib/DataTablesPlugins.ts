import DataTable from "datatables.net-bs5";

/**
 * Create a toggle button
 * @param id The id of the toggle button
 * @param label The label to use for the toggle button
 * @param onToggle The function to call when the toggle button is toggled
 * @returns A jQuery object representing the toggle button
 */
function createToggleButton(id:string, label:string, checked: boolean, onToggle:(ev:JQuery.Event)=>void) {
    const element = $(`
    <div class="pull-end">
        <div class="form-check form-switch">
            <input class="form-check-input" type="checkbox" role="switch" id="${id}" ${checked ? 'checked' : ''}>
            <label class="form-check-label" for="${id}">${label}</label>
        </div>
    </div>`);

    element.find(`#${id}`).on('change', (ev) => onToggle(ev));

    return element;
}

// I feel using the "proper" toggle from bootstrap is better than the custom one and adding extra "fluff" to the datatables code in my opinion
DataTable.feature.register('fullscreen', function (settings, opts) {
    return createToggleButton('fullscreen-button', 'Fullscreen', opts.checked, opts.onToggle);
});