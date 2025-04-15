import 'testing/globals.definitions';
import { createElement } from "./elementFactory";
import { describe, it, expect } from "@jest/globals"

describe('Element factory tests', () => {
    it('Should create a basic DIV element', () => {
        const expected = $(document.createElement('div'));
        const result = createElement('div', {});
        expect(result).toEqual(expected);
    });

    it('Should create a DIV element with an ID', () => {
        const el = document.createElement('div');
        el.id = "testElement";
        const expected = $(el);
        const result = createElement('div', { id: 'testElement' });
        expect(result).toEqual(expected);
    });

    it('Should create a DIV element with a Class', () => {
        const el = document.createElement('div');
        el.classList.add("testClass");
        const expected = $(el);
        const result = createElement('div', { classList: ['testClass'] });
        expect(result).toEqual(expected);
    });

    it('Should create a DIV element with multiple Classes', () => {
        const el = document.createElement('div');
        el.classList.add("testClass", "testClass2");
        const expected = $(el);
        const result = createElement('div', { classList: ['testClass', 'testClass2'] });
        expect(result).toEqual(expected);
    });

    it('Should create a text input element', () => {
        const el = document.createElement('input');
        el.type = 'text';
        const expected = $(el);
        const result = createElement('input', { type: 'text' });
        expect(result).toEqual(expected);
    });
});