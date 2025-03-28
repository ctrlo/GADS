/**
 * Position the disclosure popover below the trigger element
 * @param {number} offsetTop The top offset of the trigger element
 * @param {number} offsetLeft The left offset of the trigger element
 * @param {number} triggerHeight The height of the trigger element
 */
const positionDisclosure = function (offsetTop, offsetLeft, triggerHeight) {
  const left = offsetLeft + 'px'
  const top = offsetTop + triggerHeight + 'px'

  this.css({
    left: left,
    top: top
  })

  // If the popover is outside the body move it a bit to the left
  if (
    document.body &&
    document.body.clientWidth &&
    this.get(0).getBoundingClientRect
  ) {
    const windowOffset =
      document.body.clientWidth -
      this.get(0).getBoundingClientRect().right
    if (windowOffset < 0) {
      this.css({
        left: offsetLeft + windowOffset + 'px'
      })
    }
  }
}

/**
 * Toggle the state of a disclosure
 * @param {JQuery.Event} e The event that triggered the disclosure toggle
 * @param {JQuery<HTMLElement>} $trigger The element that triggered the disclosure toggle
 * @param {boolean} state The state of the disclosure (true for expanded, false for collapsed)
 * @param {boolean} permanent Is the disclosure permanently expanded
 */
const toggleDisclosure = function (e, $trigger, state, permanent) {
  $trigger.attr('aria-expanded', state)
  $trigger.toggleClass('expanded--permanent', state && permanent)

  const expandedLabel = $trigger.data('label-expanded')
  const collapsedLabel = $trigger.data('label-collapsed')

  if (collapsedLabel && expandedLabel) {
    $trigger.text(state ? expandedLabel : collapsedLabel)
  }

  const $disclosure = $trigger.siblings('.expandable').first()
  $disclosure.toggleClass('expanded', state)

  if ($disclosure.hasClass('popover')) {
    const offset = $trigger.offset()
    let top = offset.top
    let left = offset.left

    const offsetParent = $trigger.offsetParent()
    if (offsetParent) {
      const offsetParentOffset = offsetParent.offset()
      top = top - offsetParentOffset.top
      left = left - offsetParentOffset.left
    }
    positionDisclosure.call($disclosure, top, left, $trigger.outerHeight() + 6)
  }

  $trigger.trigger(state ? 'expand' : 'collapse', $disclosure)

  // If this element is within another element that also has a handler, then
  // stop that second handler also doing its action. E.g. for a more-less
  // widget within a table row, do not action both the more-less widget and
  // the opening of a record by clicking on the row
  e.stopPropagation()
}

/**
 * Handle a click event on a disclosure trigger
 * @param {JQuery.Event} e The event that triggered the disclosure toggle
 */
const onDisclosureClick = function (e) {
  const $trigger = $(this)
  const currentlyPermanentExpanded = $trigger.hasClass('expanded--permanent')
  toggleDisclosure(e, $trigger, !currentlyPermanentExpanded, true)
}

/**
 * Handle a mouseover event on a disclosure trigger
 * @param {JQuery.Event} e The event that triggered the disclosure toggle
 */
const onDisclosureMouseover = function (e) {
  const $trigger = $(this)
  const currentlyExpanded = $trigger.attr('aria-expanded') === 'true'

  if (!currentlyExpanded) {
    toggleDisclosure(e, $trigger, true, false)
  }
}

/**
 * Handle a mouseout event on a disclosure trigger
 * @param {JQuery.Event} e The event that triggered the disclosure toggle
 */
const onDisclosureMouseout = function (e) {
  const $trigger = $(this)
  const currentlyExpanded = $trigger.attr('aria-expanded') === 'true'
  const currentlyPermanentExpanded = $trigger.hasClass('expanded--permanent')

  if (currentlyExpanded && !currentlyPermanentExpanded) {
    toggleDisclosure(e, $trigger, false, false)
  }
}

/**
 * Setup all disclosure widgets within a given context
 * @param {*} context The context in which to search for disclosure widgets
 */
const setupDisclosureWidgets = function (context) {
  $('.trigger[aria-expanded]', context).on('click keydown', function (ev) {
    if (ev.type === 'click' || (ev.type === 'keydown' && (ev.which === 13 || ev.which === 32))) {
      ev.preventDefault();
      onDisclosureClick.call(this, ev);
    }
  });

  // Also show/hide disclosures on hover for widgets with the data-expand-on-hover attribute set to true
  $('.trigger[aria-expanded][data-expand-on-hover=true]', context).on('mouseover', onDisclosureMouseover)
  $('.trigger[aria-expanded][data-expand-on-hover=true]', context).on('mouseout', onDisclosureMouseout)
}

export { setupDisclosureWidgets, onDisclosureClick }
