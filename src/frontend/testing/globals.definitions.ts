import { XmlHttpRequestLike } from "../js/lib/util/upload/UploadControl";

function mockJQueryAjax() {
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

function mockJSTree() {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
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
    responseText: string = JSON.stringify({ error: 0 });
    upload = {
        onprogress: jest.fn()
    }
}

export function setupCrypto() {
    const crypto = {
        subtle: {
            importKey: jest.fn(),
            exportKey: jest.fn(),
            encrypt: jest.fn(),
            decrypt: jest.fn().mockReturnValue(new TextEncoder().encode("value")), // We mock the return on this one purely to make sure we're calling as expected
            deriveKey: jest.fn(),
        },
        getRandomValues: jest.fn().mockReturnValue(new Uint8Array(12)),
    };
    Object.defineProperty(window, "crypto", {
        value: crypto
    });
}

export async function setupNoMockCrypto() {
    const crypto = await import("crypto");
    Object.defineProperty(window, "crypto", {
        value: crypto
    });
}

export function killNoMockCrypto() {
    // @ts-expect-error This is a unit test, so this is not readonly
    delete window.crypto;
}
