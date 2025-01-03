import { getComponentElements, initializeComponent } from 'component';
import AutosaveComponent from './lib/component';
import AutosaveModal from './lib/modal';
import gadsStorage from 'util/gadsStorage';

export default (scope) => {
    try {
        if (getComponentElements(scope, '.linkspace-field').length === 0) return;
        if (getComponentElements(scope, '#restoreValuesModal').length === 0) return;

        if (gadsStorage.enabled) {
            initializeComponent(scope, '.linkspace-field', AutosaveComponent);
            initializeComponent(scope, '#restoreValuesModal', AutosaveModal);
        } else {
            $('.content-block__main-content').first().prepend("<div class='alert alert-warning mt-0 mb-3'>Autorecover is disabled because your browser lacks encryption support.</div>");
        }
    } catch (e) {
        console.error(e);
        $('.content-block__main-content').first().prepend(`<div class='alert alert-warning mt-0 mb-3'><p>Autorecover is disabled because your browser lacks encryption support.</p><p>${e.message ? e.message : e}</p></div>`);
    }
};
