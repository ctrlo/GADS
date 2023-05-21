import { initializeComponent } from 'component'
import ValueLookupComponent from './lib/component'

export default (scope) => initializeComponent(scope, '[data-lookup-endpoint]', ValueLookupComponent)
