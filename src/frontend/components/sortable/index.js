import { initializeComponent } from 'component'
import SortableComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.sortable', SortableComponent)
