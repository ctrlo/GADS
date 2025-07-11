import { XmlHttpRequestLike } from "../js/lib/util/upload/UploadControl";

/**
 * Mock the JQuery AJAX function
 */
export function mockJQueryAjax() {
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

/**
 * Mocks the jstree function to return a mock implementation
 */
export function mockJSTree() {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    $.fn.jstree = jest.fn().mockImplementation((arg: boolean) => {
        return {
            get_json: () => {
                return {};
            }
        };
    });
}

/**
 * Mock XMLHttpRequest for testing purposes
 */
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
}

/**
 * Mocks an element like interface for testing
 */
export interface ElementLike {
    hasClass: (className: string) => boolean;
    addClass: (className: string) => void;
    attr: (attr: string, value: string) => void;
    css: (attr: string, value: string) => void;
    removeClass: (className: string) => void;
    removeAttr: (attr: string) => void;
}

/**
 * Default implementation of ElementLike for testing purposes
 */
export class DefaultElementLike implements ElementLike {
    hasClass: (className: string) => boolean = jest.fn().mockReturnValue(false);
    addClass: (className: string) => void = jest.fn();
    attr: (attr: string, value: string) => void = jest.fn();
    css: (attr: string, value: string) => void = jest.fn();
    removeClass: (className: string) => void = jest.fn();
    removeAttr: (attr: string) => void = jest.fn();
}

/**
 * Sets up the crypto object for testing purposes
 * This is used to mock the crypto API in tests
 */
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

/**
 * Clear all the mocks and import a full implementation of the crypto API
 */
export async function setupNoMockCrypto() {
    const crypto = await import("crypto");
    Object.defineProperty(window, "crypto", {
        value: crypto
    });
}

/**
 * Clear the crypto implementation from the browser (for testing)
 */
export function killNoMockCrypto() {
    // @ts-expect-error This is a unit test, so this is not readonly
    delete window.crypto;
}