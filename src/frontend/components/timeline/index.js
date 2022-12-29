import { initializeComponent } from 'component'
import setupTimeline from './lib/component'

export default (scope) => initializeComponent(scope, '.timeline', setupTimeline)
