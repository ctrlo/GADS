import { Component } from 'component'
import tippy from 'tippy.js'

class TippyComponent extends Component {
  constructor(element)  {
      super(element)
      this.el = $(this.element)
  }

  initTippy(wrapperEl) {
    tippy(this.element, {
      theme: 'light',
      allowHTML: true,
      interactive: true,
      appendTo: wrapperEl,      
    })
  }
}

export default TippyComponent
