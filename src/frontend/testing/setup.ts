import { TextEncoder, TextDecoder } from "util";

Object.assign(global, { TextEncoder, TextDecoder });

declare global {
    interface Window {
        $: JQueryStatic;
        jQuery: JQueryStatic;
        alert: (message?: any) => void;
    }
}

window.$ = window.jQuery = require("jquery"); // eslint-disable-line @typescript-eslint/no-require-imports
window.alert = jest.fn();