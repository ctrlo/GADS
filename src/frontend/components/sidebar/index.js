import { initializeComponent } from 'component';
import SidebarComponent from './lib/component';

export default (scope) => initializeComponent(scope, '.sidebar', SidebarComponent);
