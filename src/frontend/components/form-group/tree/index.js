import { initializeComponent } from 'component'
import TreeComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.tree', TreeComponent)
