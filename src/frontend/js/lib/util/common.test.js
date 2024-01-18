import { addClass, fromJson, hideElement, removeClass, showElement, stopPropagation } from "./common";

describe('common functions', () => {
    describe('event handling', () => {
        it('stops propagation', () => {
            const ev = {
                stopPropagation: jest.fn(),
                preventDefault: jest.fn()
            };
            stopPropagation(ev);
            expect(ev.stopPropagation).toHaveBeenCalled();
            expect(ev.preventDefault).toHaveBeenCalled();
        });
    });

    describe('CSS and ARIA',()=>{
        it('hides an element', () => {
            const el = {
                hasClass: jest.fn().mockReturnValue(false),
                addClass: jest.fn(),
                attr: jest.fn(),
                css: jest.fn()
            };
            hideElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.addClass).toHaveBeenCalledWith('hidden');
            expect(el.attr).toHaveBeenCalledWith('aria-hidden', 'true');
        });

        it('does not hide a hidden element', () => {
            const el = {
                hasClass: jest.fn().mockReturnValue(true),
                addClass: jest.fn(),
                attr: jest.fn()
            };
            hideElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.addClass).not.toHaveBeenCalled();
            expect(el.attr).not.toHaveBeenCalled();
        });

        it('shows a hidden element', () => {
            const el = {
                hasClass: jest.fn().mockReturnValue(true),
                removeClass: jest.fn(),
                removeAttr: jest.fn(),
                css: jest.fn()
            };
            showElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.removeClass).toHaveBeenCalledWith('hidden');
            expect(el.removeAttr).toHaveBeenCalledWith('aria-hidden');
        });

        it('does not show a visible element', () => {
            const el = {
                hasClass: jest.fn().mockReturnValue(false),
                removeClass: jest.fn(),
                removeAttr: jest.fn()
            };
            showElement(el);
            expect(el.hasClass).toHaveBeenCalledWith('hidden');
            expect(el.removeClass).not.toHaveBeenCalled();
            expect(el.removeAttr).not.toHaveBeenCalled();
        });

        it('adds a class', ()=> {
            const el = {
                hasClass: jest.fn().mockReturnValue(false),
                addClass: jest.fn()
            };
            addClass(el, 'foo');
            expect(el.hasClass).toHaveBeenCalledWith('foo');
            expect(el.addClass).toHaveBeenCalledWith('foo');
        });

        it('does not add a class if it already exists', ()=> {
            const el = {
                hasClass: jest.fn().mockReturnValue(true),
                addClass: jest.fn()
            };
            addClass(el, 'foo');
            expect(el.hasClass).toHaveBeenCalledWith('foo');
            expect(el.addClass).not.toHaveBeenCalled();
        });

        it('removes a class', ()=> {
            const el = {
                hasClass: jest.fn().mockReturnValue(true),
                removeClass: jest.fn()
            };
            removeClass(el, 'foo');
            expect(el.hasClass).toHaveBeenCalledWith('foo');
            expect(el.removeClass).toHaveBeenCalledWith('foo');
        });

        it('does not remove a class if it does not exist', ()=> {
            const el = {
                hasClass: jest.fn().mockReturnValue(false),
                removeClass: jest.fn()
            };
            removeClass(el, 'foo');
            expect(el.hasClass).toHaveBeenCalledWith('foo');
            expect(el.removeClass).not.toHaveBeenCalled();
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
