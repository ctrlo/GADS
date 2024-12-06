import { initializeComponent } from 'component';
import AutosaveComponent from './lib/component';
import AutosaveModal from './lib/modal';

export default (scope) => {
    initializeComponent(scope, '.linkspace-field', AutosaveComponent);
    initializeComponent(scope, '#restoreValuesModal', AutosaveModal);
};
