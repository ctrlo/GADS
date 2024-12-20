import {XmlHttpRequestLike} from "util/upload/UploadControl";
import {jest} from '@jest/globals';

declare global {
  interface Window {
    $: JQueryStatic;
    jQuery: JQueryStatic;
    alert: (message?: any) => void;
  }
}

window.$ = window.jQuery = require("jquery");
window.alert = jest.fn();

export function mockJQueryAjax() {
  // @ts-expect-error - This is a global function
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
  // @ts-expect-error - This is a global function
  $.fn.jstree = jest.fn().mockImplementation(() => {
    return {
      get_json: () => {
        return {};
      }
    };
  });
}

export class MockXhr implements XmlHttpRequestLike {
  open: (method: string, url: string) => void = jest.fn();
  onabort?: ((this: XMLHttpRequest, ev: ProgressEvent) => any) | null | undefined = jest.fn();
  onerror?: ((this: XMLHttpRequest, ev: ProgressEvent) => any) | null | undefined = jest.fn();
  onprogress?: ((e: ProgressEvent) => void) | null | undefined = jest.fn();
  onreadystatechange: ((this: XMLHttpRequest, ev: Event) => any) | null = jest.fn();
  send: (data?: Document | XMLHttpRequestBodyInit | null | undefined) => void = jest.fn();
  setRequestHeader: (header: string, value: string) => void = jest.fn();
  readyState: number = 4;
  status: number = 200;
  responseText: string = JSON.stringify({error: 0});
}
