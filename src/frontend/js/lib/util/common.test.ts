import "testing";
import { fromJson, hideElement, showElement } from "./common";

describe('common functions', () => {
    //TODO: This all need migrating to use "spy" and "spyOn" from Jest
    describe('CSS and ARIA', () => {
        let el: HTMLDivElement;

        beforeEach(() => {
            el = document.createElement('div');
        });

        it('hides an element', () => {
            const elSpy = jest.spyOn(el, 'setAttribute');
            hideElement(el);
            expect(elSpy).toHaveBeenCalledWith('aria-hidden', 'true');
        });

        it('does not hide a hidden element', () => {
            el.classList.add('hidden');
            el.ariaHidden = 'true';
            const elSpy = jest.spyOn(el, 'setAttribute');
            hideElement(el);
            expect(elSpy).not.toHaveBeenCalled();
        });

        it('shows a hidden element', () => {
            el.classList.add('hidden');
            el.ariaHidden = 'true';
            const elSpy = jest.spyOn(el, 'removeAttribute');
            showElement(el);
            expect(elSpy).toHaveBeenCalledWith('aria-hidden');
        });

        it('does not show a visible element', () => {
            const elSpy = jest.spyOn(el, 'removeAttribute');
            showElement(el);
            expect(elSpy).not.toHaveBeenCalled();
        });
    });

    describe('JSON tests', () => {
        interface TestObject {
            foo: string;
        }

        it('parses a JSON string', () => {
            const json = '{"foo":"bar"}';
            const parsed = fromJson<TestObject>(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('parses a JSON object', () => {
            const json = { foo: "bar" };
            const parsed = fromJson(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('throws an error for invalid JSON', () => {
            const json = "foo";
            expect(() => { fromJson(json); }).toThrow('Invalid JSON');
        });

        it('throws an error for null', () => {
            const json = null;
            expect(() => { fromJson(json); }).toThrow('Empty JSON');
        });

        it('throws an error for undefined', () => {
            const json = undefined;
            expect(()=>{ fromJson(json);}).toThrow('Empty JSON');
        });
    });
});
