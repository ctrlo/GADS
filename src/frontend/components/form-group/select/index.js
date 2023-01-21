import { initializeComponent } from 'component'
import SelectComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.select', SelectComponent)
