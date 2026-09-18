/* eslint-disable @typescript-eslint/ban-ts-comment */
import { fromJson, hideElement, showElement } from './common';
import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';

describe('common functions', () => {
    describe('CSS and ARIA', () => {
        let el: JQuery<HTMLElement>;

        beforeEach(() => {
            el = $(document.createElement('div'));
        });

        afterEach(() => {
            jest.clearAllMocks();
        });

        it('hides an element', () => {
            const hasClass = $.fn.hasClass = jest.fn().mockReturnValue(false);
            const addClass = $.fn.addClass = jest.fn();
            const attr = $.fn.attr = jest.fn();
            hideElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(addClass).toHaveBeenCalledWith('hidden');
            expect(attr).toHaveBeenCalledWith('aria-hidden', 'true');
        });

        it('does not hide a hidden element', () => {
            el.addClass('hidden');
            const hasClass = $.fn.hasClass = jest.fn().mockReturnValue(true);
            const addClass = $.fn.addClass = jest.fn();
            const attr = $.fn.attr = jest.fn();
            hideElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(addClass).not.toHaveBeenCalled();
            expect(attr).not.toHaveBeenCalled();
        });

        it('shows a hidden element', () => {
            el.addClass('hidden');
            const hasClass = $.fn.hasClass = jest.fn().mockReturnValue(true);
            const removeClass = $.fn.removeClass = jest.fn();
            const removeAttr = $.fn.removeAttr = jest.fn();
            showElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(removeClass).toHaveBeenCalledWith('hidden');
            expect(removeAttr).toHaveBeenCalledWith('aria-hidden');
        });

        it('does not show a visible element', () => {
            const hasClass = $.fn.hasClass = jest.fn().mockReturnValue(false);
            const removeClass = $.fn.removeClass = jest.fn();
            const removeAttr = $.fn.removeAttr = jest.fn();
            showElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(removeClass).not.toHaveBeenCalled();
            expect(removeAttr).not.toHaveBeenCalled();
        });
    });

    describe('JSON tests', () => {
        it('parses a JSON string', () => {
            const json = '{"foo":"bar"}';
            const parsed = fromJson(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('parses a JSON object', () => {
            const json = { foo: 'bar' };
            const parsed = fromJson(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('returns an empty object for invalid JSON', () => {
            const json = 'foo';
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for null', () => {
            const json = null;
            /* @ts-ignore */
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for undefined', () => {
            const json = undefined;
            /* @ts-ignore */
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });
    });
});
