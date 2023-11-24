import { hideElement, showElement, stopPropagation } from "./common";

describe('common functions', () => {
    it('stops propagation', () => {
        const ev = {
            stopPropagation: jest.fn(),
            preventDefault: jest.fn()
        };
        stopPropagation(ev);
        expect(ev.stopPropagation).toHaveBeenCalled();
        expect(ev.preventDefault).toHaveBeenCalled();
    });

    it('hides an element', () => {
        const el = {
            hasClass: jest.fn().mockReturnValue(false),
            addClass: jest.fn(),
            attr: jest.fn()
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
            removeAttr: jest.fn()
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
});
