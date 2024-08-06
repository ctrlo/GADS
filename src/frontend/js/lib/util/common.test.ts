import "../../../testing/globals.definitions";
import { DefaultElementLike, ElementLike } from "../../../testing/globals.definitions";
import { fromJson, hideElement, showElement } from "./common";

describe('common functions', () => {
    describe('CSS and ARIA',()=>{
        let el:ElementLike;

        beforeEach(() => {
            el=new DefaultElementLike();
        });

        afterEach(() => {
            jest.clearAllMocks();
        });

        it('hides an element', () => {
            hideElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.addClass).toHaveBeenCalledWith('hidden');
            expect(el.attr).toHaveBeenCalledWith('aria-hidden', 'true');
        });

        it('does not hide a hidden element', () => {
            el.hasClass = jest.fn().mockReturnValue(true);
            hideElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.addClass).not.toHaveBeenCalled();
            expect(el.attr).not.toHaveBeenCalled();
        });

        it('shows a hidden element', () => {
            el.hasClass = jest.fn().mockReturnValue(true);
            showElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.removeClass).toHaveBeenCalledWith('hidden');
            expect(el.removeAttr).toHaveBeenCalledWith('aria-hidden');
        });

        it('does not show a visible element', () => {
            el.hasClass= jest.fn().mockReturnValue(false);
            showElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.removeClass).not.toHaveBeenCalled();
            expect(el.removeAttr).not.toHaveBeenCalled();
        });
    });

    describe('JSON tests',() => {
        it('parses a JSON string', () => {
            const json = '{"foo":"bar"}';
            const parsed = fromJson(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('parses a JSON object', ()=>{
            const json = {foo: "bar"};
            const parsed = fromJson(json);
            expect(parsed.foo).toEqual('bar');
        });

        it('returns an empty object for invalid JSON', ()=>{
            const json = "foo";
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for null', ()=>{
            const json = null;
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for undefined', ()=>{
            const json = undefined;
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });
    });
});
