var positionDisclosure = function(offsetTop, offsetLeft, triggerHeight) {
  var $disclosure = this;

  var left = offsetLeft + "px";
  var top = offsetTop + triggerHeight + "px";

  $disclosure.css({
    left: left,
    top: top
  });

  // If the popover is outside the body move it a bit to the left
  if (
    document.body &&
    document.body.clientWidth &&
    $disclosure.get(0).getBoundingClientRect
  ) {
    var windowOffset =
      document.body.clientWidth -
      $disclosure.get(0).getBoundingClientRect().right;
    if (windowOffset < 0) {
      $disclosure.css({
        left: offsetLeft + windowOffset + "px"
      });
    }
  }
};

var toggleDisclosure = function(e, $trigger, state, permanent) {
  $trigger.attr("aria-expanded", state);
  $trigger.toggleClass("expanded--permanent", state && permanent);

  var expandedLabel = $trigger.data("label-expanded");
  var collapsedLabel = $trigger.data("label-collapsed");

  if (collapsedLabel && expandedLabel) {
    $trigger.html(state ? expandedLabel : collapsedLabel);
  }

  var $disclosure = $trigger.siblings(".expandable").first();
  $disclosure.toggleClass("expanded", state);

  if ($disclosure.hasClass("popover")) {
    var offset = $trigger.offset();
    var top = offset.top;
    var left = offset.left;

    var offsetParent = $trigger.offsetParent();
    if (offsetParent) {
      var offsetParentOffset = offsetParent.offset();
      top = top - offsetParentOffset.top;
      left = left - offsetParentOffset.left;
    }
    positionDisclosure.call($disclosure, top, left, $trigger.outerHeight() + 6);
  }

  $trigger.trigger(state ? "expand" : "collapse", $disclosure);

  // If this element is within another element that also has a handler, then
  // stop that second handler also doing its action. E.g. for a more-less
  // widget within a table row, do not action both the more-less widget and
  // the opening of a record by clicking on the row
  e.stopPropagation();
};

var onDisclosureClick = function(e) {
  var $trigger = $(this);
  var currentlyPermanentExpanded = $trigger.hasClass("expanded--permanent");

  toggleDisclosure(e, $trigger, !currentlyPermanentExpanded, true);
};

var onDisclosureMouseover = function(e) {
  var $trigger = $(this);
  var currentlyExpanded = $trigger.attr("aria-expanded") === "true";

  if (!currentlyExpanded) {
    toggleDisclosure(e, $trigger, true, false);
  }
};

var onDisclosureMouseout = function(e) {
  var $trigger = $(this);
  var currentlyExpanded = $trigger.attr("aria-expanded") === "true";
  var currentlyPermanentExpanded = $trigger.hasClass("expanded--permanent");

  if (currentlyExpanded && !currentlyPermanentExpanded) {
    toggleDisclosure(e, $trigger, false, false);
  }
};

var setupDisclosureWidgets = function(context) {
  $(".trigger[aria-expanded]", context).on("click", onDisclosureClick);

  // Also show/hide disclosures on hover in the data-table
  $(".trigger[aria-expanded]", context).on("mouseover", onDisclosureMouseover);
  $(".trigger[aria-expanded]", context).on("mouseout", onDisclosureMouseout);
};

export { setupDisclosureWidgets, onDisclosureClick };
