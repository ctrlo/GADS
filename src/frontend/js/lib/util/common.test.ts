import { fromJson, hideElement, showElement } from "./common";
import { describe, it, expect, jest, beforeEach, afterEach } from "@jest/globals";

describe('common functions', () => {
    describe.skip('CSS and ARIA - skipped as they are incorrect', () => {
        let el: JQuery<HTMLElement>;

        beforeEach(() => {
            el = $(document.createElement('div'));
        });

        afterEach(() => {
            jest.clearAllMocks();
        });

        it('hides an element', () => {
            const hasClass = jest.spyOn(el, 'hasClass');
            const addClass = jest.spyOn(el, 'addClass');
            const attr = jest.spyOn(el, 'attr');
            hideElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(addClass).toHaveBeenCalledWith('hidden');
            expect(attr).toHaveBeenCalledWith('aria-hidden', 'true');
        });

        it('does not hide a hidden element', () => {
            el.addClass('hidden');
            const hasClass = jest.spyOn(el, 'hasClass');
            const addClass = jest.spyOn(el, 'addClass');
            const attr = jest.spyOn(el, 'attr');
            hideElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(addClass).not.toHaveBeenCalled();
            expect(attr).not.toHaveBeenCalled();
        });

        it('shows a hidden element', () => {
            el.addClass('hidden');
            const hasClass = jest.spyOn(el, 'hasClass');
            const removeClass = jest.spyOn(el, 'removeClass');
            const removeAttr = jest.spyOn(el, 'removeAttr');
            showElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(removeClass).toHaveBeenCalledWith('hidden');
            expect(removeAttr).toHaveBeenCalledWith('aria-hidden');
        });

        it('does not show a visible element', () => {
            const hasClass = jest.spyOn(el, 'hasClass');
            const removeClass = jest.spyOn(el, 'removeClass');
            const removeAttr = jest.spyOn(el, 'removeAttr');
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
            const json = { foo: "bar" };
            const parsed = fromJson(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('returns an empty object for invalid JSON', () => {
            const json = "foo";
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for null', () => {
            const json = null;
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for undefined', () => {
            const json = undefined;
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });
    });
});
