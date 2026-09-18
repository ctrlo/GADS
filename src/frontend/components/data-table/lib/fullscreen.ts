import DataTable, { Api, Config } from "datatables.net-bs5";

// Extended config object to allow for fullscreen
type DtConfig = Config & {
    fullscreen?: boolean;
    element?: JQuery<HTMLElement>;
};

/**
 * Create a toggle button
 * @param id The id of the toggle button
 * @param label The label to use for the toggle button
 * @param onToggle The function to call when the toggle button is toggled
 * @returns A jQuery object representing the toggle button
 */
function createToggleButton(id: string, label: string, checked: boolean, onToggle: (ev: JQuery.Event) => void) {
    const element = $(`
    <div class="dt-toggle-button">
        <div class="custom-control form-check form-switch">
            <input class="custom-control-input form-check-input" type="checkbox" role="switch" id="${id}" ${checked ? "checked=\"checked\"" : ""}>
            <label class="custom-control-label form-check-label" for="${id}">${label}</label>
        </div>
    </div>`);

    element.find(`#${id}`).on("change", onToggle);

    return element;
}

/**
 * Toggle fullscreen mode for the DataTable
 * @param api The DataTables API instance to use
 */
const toggle = (api: Api) => {
    let conf: DtConfig = api.init();
    let fullscreen = conf.fullscreen;
    const node = api.table().node();

    console.log("Destroy the DT");
    api.destroy();

    if (!fullscreen) {
        console.log("Entering fullscreen mode");
        fullscreen = true;

        const frame = document.createElement("div");
        frame.className = "p-3";
        frame.id = "fullscreen-frame";
        frame.style.position = "fixed";
        frame.style.top = "0";
        frame.style.left = "0";
        frame.style.width = "100%";
        frame.style.height = "100%";
        frame.style.overflow = "auto";
        frame.style.backgroundColor = "white";
        frame.style.zIndex = "1021";
        frame.style.overflow = "auto";

        const newTable = node.cloneNode(true);
        const $table = $(newTable);

        $table.appendTo(frame);

        document.body.appendChild(frame);

        conf = Object.assign(conf, { responsive: false, reinitialize: true, el: $table, fullscreen });
        console.log("Reinitializing the DT in fullscreen mode");
        $table.DataTable(conf);
    } else {
        fullscreen = false;

        console.log("Removing the fullscreen frame");
        $("#fullscreen-frame").remove();

        console.log("Reinitializing the DT in normal mode");
        conf = (Object.assign(conf, { reinitialize: true, fullscreen }));
        conf.element?.DataTable(conf);
    }
};

// I feel using the "proper" toggle from bootstrap is better than the custom one and adding extra "fluff" to the datatables code in my opinion
DataTable.feature.register("fullscreen", function (settings, opts) {
    const options = Object.assign({
        checked: settings.api.init().fullscreen
    }, opts);
    return createToggleButton("fullscreen-button", "Fullscreen", options.checked, () => {
        const api = settings.api;
        toggle(api);
        // api.destroy();
        // new DataTable(api.table().node(), result);
    });
});
