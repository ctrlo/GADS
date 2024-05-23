declare global {
    interface Window {
        $: JQueryStatic;
        alert: (message?: any)=>void;
    }
}

window.$ = require("jquery");
window.alert = jest.fn();

/**
 * Initializes the global variables that are used in the tests
 * These include the jQuery ajax function and the jstree function
 * @returns void
 */
export default function initGlobals() {
    $.ajax = jest.fn().mockImplementation(() => {
        return {
            done: (callback: () => void) => {
                callback();
            }
        };
    })
    // @ts-expect-error I don't care enough to fix this
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    $.fn.jstree = jest.fn().mockImplementation((arg: boolean) => {
        return {
            get_json: () => {
                return {};
            }
        };
    })
}