import {initializeComponent} from 'component'
import DependentFieldsComponent from './lib/component'

export default (scope) => initializeComponent(scope, '[data-has-dependency]', DependentFieldsComponent)
