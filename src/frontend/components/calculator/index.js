import { initializeComponent } from 'component'
import CalculatorComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.calculator', CalculatorComponent)
