import { TextEncoder, TextDecoder } from "util";

Object.assign(global, { TextEncoder, TextDecoder }); // Polyfill for TextEncoder and TextDecoder as Jest doesn't load these by default

declare global {
    interface Window {
        $: JQueryStatic;
        jQuery: JQueryStatic;
        alert: (message?: any) => void;
    }
}

// JQuery isn't enabled by default in Jest
window.$ = window.jQuery = require("jquery"); // eslint-disable-line @typescript-eslint/no-require-imports
window.alert = jest.fn(); // Mocking alert function