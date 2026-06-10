import { TextEncoder, TextDecoder } from "util";
import $ from "jquery";

Object.assign(global, { TextEncoder, TextDecoder });

declare global {
    interface Window {
        $: any;
        jQuery: any;
        alert: (message?: any) => void;
    }
}

window["$"] = window["jQuery"] = $;
window.alert = jest.fn();
