import { initializeComponent } from 'component'
import OrderableSortableComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.orderable-sortable', OrderableSortableComponent)
