import { jest } from "@jest/globals";
import { TextEncoder, TextDecoder } from "util";
import $ from "jquery";

Object.assign(global, { TextEncoder, TextDecoder });

declare global {
    interface Window {
        $: JQueryStatic;
        jQuery: JQueryStatic;
        alert: (message?: any) => void;
    }
}

window.$ = window.jQuery = $;
window.alert = jest.fn();
