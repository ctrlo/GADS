import { TypeaheadBuilder } from './TypeaheadBuilder';
import {describe, expect, it} from "@jest/globals";

describe('builder', () => {
    it('should error on the typeahead input not being set', () => {
        const builder = new TypeaheadBuilder();
        builder.withCallback(() => { return; });
        builder.withName('test');
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).toThrow('Input not set');
    });

    it('should error on the typeahead callback not being set', () => {
        const builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withName('test');
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).toThrow('Callback not set');
    });

    it('should error on the typeahead name not being set', () => {
        const builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withCallback(() => { return; });
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).toThrow('Name not set');
    });

    it('should error on the typeahead ajax source not being set', () => {
        const builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withCallback(() => { return; });
        builder.withName('test');
        expect(() => { builder.build(); }).toThrow('Ajax source not set');
    });

    it('should build the typeahead', () => {
        const builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withCallback(() => { return; });
        builder.withName('test');
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).not.toThrow();
    });
});