import { initializeComponent } from 'component';
import ChronologyComponent from './lib/component';

// @ts-expect-error Components have an odd type definition
export default scope => initializeComponent(scope, '.chronology', ChronologyComponent);
