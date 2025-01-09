import { jest } from "@jest/globals";

declare global {
    interface Window {
        $: JQueryStatic;
        jQuery: JQueryStatic;
        alert: (message?: any)=>void;
    }
}

window.$ = window.jQuery = require("jquery");
window.alert = jest.fn();
