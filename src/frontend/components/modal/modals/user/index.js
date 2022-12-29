import { initializeComponent } from 'component'
import UserModalComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.modal--user', UserModalComponent)
