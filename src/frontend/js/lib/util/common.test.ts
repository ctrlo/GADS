import "../../../testing/globals.definitions";
import { fromJson, hideElement, showElement } from "./common";

describe('common functions', () => {
    describe('CSS and ARIA', () => {
        let el: HTMLDivElement;

        beforeEach(() => {
            el = document.createElement('div');
        });

        afterEach(() => {
            jest.clearAllMocks();
        });

        it('hides an element', () => {
            const cl = el.classList;
            const hasClass = jest.spyOn(cl, 'contains')
            const addClass = jest.spyOn(cl, 'add');
            const attr = jest.spyOn(el, 'setAttribute');
            hideElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(addClass).toHaveBeenCalledWith('hidden');
            expect(attr).toHaveBeenCalledWith('aria-hidden', 'true');
        });

        it('does not hide a hidden element', () => {
            el.classList.add('hidden');
            const cl = el.classList;
            const hasClass = jest.spyOn(cl, 'contains')
            const addClass = jest.spyOn(cl, 'add');
            const attr = jest.spyOn(el, 'setAttribute');
            hideElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(addClass).not.toHaveBeenCalled();
            expect(attr).not.toHaveBeenCalled();
        });

        it('shows a hidden element', () => {
            el.classList.add('hidden');
            const cl = el.classList;
            const hasClass = jest.spyOn(cl, 'contains')
            const removeClass = jest.spyOn(cl, 'remove');
            const removeAttr = jest.spyOn(el, 'removeAttribute');
            showElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(removeClass).toHaveBeenCalledWith('hidden');
            expect(removeAttr).toHaveBeenCalledWith('aria-hidden');
        });

        it('does not show a visible element', () => {
            const cl = el.classList;
            const hasClass = jest.spyOn(cl, 'contains')
            const removeClass = jest.spyOn(cl, 'remove');
            const removeAttr = jest.spyOn(el, 'removeAttribute');
            showElement(el);
            expect(hasClass).toHaveBeenCalledWith('hidden');
            expect(removeClass).not.toHaveBeenCalled();
            expect(removeAttr).not.toHaveBeenCalled();
        });
    });

    describe('JSON tests', () => {
        it('parses a JSON string', () => {
            const json = '{"foo":"bar"}';
            const parsed: any = fromJson<{foo: string}>(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('parses a JSON object', () => {
            const json = { foo: "bar" };
            const parsed: any = fromJson(json);
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
