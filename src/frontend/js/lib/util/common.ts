import { isNumber, isObject, isString } from "vis-util";
import { isArray } from "./typechecks/lib/array";
import { hasMethod } from "./typechecks/lib/object";

export const hideElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if ($el.hasClass('hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if (!$el.hasClass('hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

export const fromJson = (json: String | object) => {
    try {
        // An empty string returns false in a boolean context, this also covers null and undefined
        if (!json || json === '') return {};
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch (e) {
        return {};
    }
}

export const stringifyValue = (value: unknown): string => {
    if (isString(value)) {
        return value;
    } else if (isNumber(value)) {
        return value.toString();
    } else if (isArray(value)) {
        return value.map(stringifyValue).join(", ");
    } else if (hasMethod(value, "toString") && value.toString !== Object.prototype.toString) { // Need to make sure toString is not the default one
        return value.toString();
    } else if (isObject(value)) {
        return JSON.stringify(value);
    }
    return String(value);
}