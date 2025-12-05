import { initializeComponent } from 'component';
import CurvalModalComponent from './lib/component';

// Originally this was an async load - this has been changed as the autosave code becomes overcomplex with async
export default (scope) => initializeComponent(scope, '.modal--curval', CurvalModalComponent);
