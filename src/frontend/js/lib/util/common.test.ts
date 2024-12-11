import "../../../testing/globals.definitions";
import { describe, beforeEach, afterEach, jest, it, expect } from "@jest/globals";
import { compare, fromJson, hideElement, showElement } from "./common";

describe('common functions', () => {
    describe('CSS and ARIA',()=>{
        let el: JQuery<HTMLDivElement>;

        beforeEach(() => {
            el= $(document.createElement('div'));
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

    describe('JSON tests',() => {
        it('parses a JSON string', () => {
            const json = '{"foo":"bar"}';
            const parsed = fromJson(json);
            // @ts-expect-error This isn't valid, but it's just for the tests
            expect(parsed.foo).toEqual('bar');
        });

        it('parses a JSON object', ()=>{
            const json = {foo: "bar"};
            const parsed = fromJson<{foo: string}>(json) as {foo: string};
            expect(parsed.foo).toEqual('bar');
        });

        it('returns an empty object for invalid JSON', ()=>{
            const json = "foo";
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for null', ()=>{
            const json = null;
            // @ts-expect-error This isn't valid, but it's just for the tests
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });

        it('returns an empty object for undefined', ()=>{
            const json = undefined;
            // @ts-expect-error This isn't valid, but it's just for the tests
            const parsed = fromJson(json);
            expect(parsed).toEqual({});
        });
    });

    describe('compare', () => {
        it('compares two objects that are the same', () => {
            const a = {foo: "bar"};
            const b = {foo: "bar"};
            expect(compare(a, b)).toBeTruthy();
        });

        it('compares two objects that are different', () => {
            const a = {foo: "bar"};
            const b = {foo: "baz"};
            expect(compare(a, b)).toBeFalsy();
        });

        it('compares two objects that are nested', () => {
            const a = {foo: {bar: "baz"}};
            const b = {foo: {bar: "baz"}};
            expect(compare(a, b)).toBeTruthy();
        });

        it('compares two objects that are nested and different', () => {
            const a = {foo: {bar: "baz"}};
            const b = {foo: {bar: "bar"}};
            expect(compare(a, b)).toBeFalsy();
        });

        it('compares two objects that are deeply nested', () => {
            const a = {foo: {bar: {baz: "qux"}}};
            const b = {foo: {bar: {baz: "qux"}}};
            expect(compare(a, b)).toBeTruthy();
        });

        it('compares two objects that are deeply nested and different', () => {
            const a = {foo: {bar: {baz: "qux"}}};
            const b = {foo: {bar: {baz: "bar"}}};
            expect(compare(a, b)).toBeFalsy();
        });
    });
});
