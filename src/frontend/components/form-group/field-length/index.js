import { initializeComponent } from 'component';
import FieldLengthComponent from './lib/component';

export default (scope) => {
    initializeComponent(scope, '[data-max]', FieldLengthComponent);
};
