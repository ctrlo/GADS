import { initializeComponent } from 'component'
import MultipleValuesComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.input--multiple-values', MultipleValuesComponent)
