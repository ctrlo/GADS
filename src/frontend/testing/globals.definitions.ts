import { XmlHttpRequestLike } from "js/lib/util/upload/UploadControl";

export function mockJQueryAjax() {
    // @ts-expect-error - jest fn
    $.ajax = jest.fn().mockImplementation(() => {
        return {
            done: (callback: () => void) => {
                callback();
            }
        };
    });
}

/**
 * Initializes the global variables that are used in the tests
 * These include the jQuery ajax function and the jstree function
 * @returns void
 */
export function initGlobals() {
    mockJQueryAjax();
    mockJSTree();
}
    
export function mockJSTree() {
    // @ts-expect-error - jest fn
    $.fn.jstree = jest.fn().mockImplementation((arg: boolean) => {
        return {
            get_json: () => {
                return {};
            }
        };
    });
}

export class MockXhr implements XmlHttpRequestLike {
    open: (method: string, url: string) => void = jest.fn();
    onabort?: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null | undefined = jest.fn();
    onerror?: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null | undefined = jest.fn();
    onprogress?: ((e: ProgressEvent) => void) | null | undefined = jest.fn();
    onreadystatechange: ((this: XMLHttpRequest, ev: Event) => any) | null = jest.fn();
    send: (data?: Document | XMLHttpRequestBodyInit | null | undefined) => void = jest.fn();
    setRequestHeader: (header: string, value: string) => void = jest.fn();
    readyState: number = 4;
    status: number = 200;
    responseText: string = JSON.stringify({error: 0});
}
