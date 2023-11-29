import { TypeaheadBuilder } from './TypeaheadBuilder';

declare global {
    interface Window {
        $: any;
    }
}

window.$ = require('jquery');

describe('builder', () => {
    it('should error on the typeahead input not being set', () => {
        var builder = new TypeaheadBuilder();
        builder.withCallback((suggestion) => { return; });
        builder.withName('test');
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).toThrow('Input not set');
    });

    it('should error on the typeahead callback not being set', () => {
        var builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withName('test');
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).toThrow('Callback not set');
    });

    it('should error on the typeahead name not being set', () => {
        var builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withCallback((suggestion) => { return; });
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).toThrow('Name not set');
    });

    it('should error on the typeahead ajax source not being set', () => {
        var builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withCallback((suggestion) => { return; });
        builder.withName('test');
        expect(() => { builder.build(); }).toThrow('Ajax source not set');
    });

    it('should build the typeahead', () => {
        var builder = new TypeaheadBuilder();
        builder.withInput($(document.createElement('input')));
        builder.withCallback((suggestion) => { return; });
        builder.withName('test');
        builder.withAjaxSource('test');
        expect(() => { builder.build(); }).not.toThrow();
    });
});
