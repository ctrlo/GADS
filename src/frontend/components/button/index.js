import { initializeComponent } from 'component';
import ButtonComponent from './lib/component';

export default (scope) => initializeComponent(scope, 'button[class*="btn-js-"]', ButtonComponent);
