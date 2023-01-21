import { initializeComponent } from 'component'
import GraphComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.graph', GraphComponent)
