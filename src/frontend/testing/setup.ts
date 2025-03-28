import { jest } from "@jest/globals";
import {TextEncoder, TextDecoder} from "util";

Object.assign(global, {TextEncoder, TextDecoder});

declare global {
    interface Window {
        $: JQueryStatic;
        jQuery: JQueryStatic;
        alert: (message?: any)=>void;
    }
}

window.$ = window.jQuery = require("jquery");
window.alert = jest.fn();
