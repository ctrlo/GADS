const setupLessMoreWidgets = (() => {
  function uuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  // Traverse up through the tree and find the parent element that is hidden
  var parentHidden = function($elem) {

    if ($elem.css('display') == 'none') {
        return $elem;
    }
    var $parent = $elem.parent();
    if (!$parent || !$parent.length) {
        return undefined;
    }
    return parentHidden($parent);
  };

  // We previously used a plugin for this
  // (https://github.com/dreamerslab/jquery.actual) but its performance was slow
  // when a page had many more-less divs
  var getActualHeight = function($elem) {

    if ($elem.attr('data-actual-height')) { // cached heights from previous runs
        return $elem.attr('data-actual-height');
    }

    if ($elem.height()) { // Assume element is visible
        return $elem.height();
    }

    // The reason this element is visible could be because of a parent element
    var $parent = parentHidden($elem, 0);

    if (!$parent) { return; }

    // Add a unique identifier to each more-less class, before cloning. Once we
    // measure the height on the cloned elements, we can apply the height as a
    // data value to its real equivalent element using this unique class.
    $parent.find('.more-less').each(function() {
        var $e = $(this);
        $e.addClass('more-less-id-' + uuid());
    });

    // Clone the element and show it to find out its height
    var $clone = $parent.clone()
                .attr("id", false)
                .css({visibility:"hidden", display:"block", position:"absolute"});
    $("body").append($clone);

    // The cloned element could contain many other hidden more-less divs, so do
    // them all at the same time to improve performance
    $clone.find('.more-less').each(function() {
        var $ml = $(this);
        var classList = $ml.attr("class").split(/\s+/);
        $.each(classList, function(index, item) {
            if (item.indexOf('more-less-id') >= 0) {
                var $toset = $parent.find('.' + item);
                // Can't use data() as it can't be re-read
                $toset.attr('data-actual-height', $ml.height());
            }
        });
    });

    $clone.remove();

    return $elem.attr('data-actual-height');
  };

  var setupLessMoreWidgets = function (context) {
    var MAX_HEIGHT = 100;

    var convert = function () {
        var $ml = $(this);
        var column = $ml.data('column');
        var content = $ml.html();

        $ml.removeClass('transparent');

        // Element may be hidden (e.g. when rendering edit fields on record page).
        if (getActualHeight($ml) < MAX_HEIGHT) {
            return;
        }

        $ml.addClass('clipped');

        var $expandable = $('<div/>', {
            'class' : 'expandable popover column-content',
            'html'  : content
        });

        var toggleLabel = 'Show ' + column + ' &rarr;';

        var $expandToggle = $('<button/>', {
            'class' : 'btn btn-xs btn-primary trigger',
            'html'  : toggleLabel,
            'type'  : 'button',
            'aria-expanded' : false,
            'data-label-expanded' : 'Hide ' + column,
            'data-label-collapsed' : toggleLabel
        });

        $expandToggle.on('toggle', function (e, state) {
            var windowWidth = $(window).width();
            var leftOffset = $expandable.offset().left;
            var minWidth = 400;
            var colWidth = $ml.width();
            var newWidth = colWidth > minWidth ? colWidth : minWidth;
            if (state === 'expanded') {
                $expandable.css('width', newWidth + 'px');
                if (leftOffset + newWidth + 20 < windowWidth) {
                    return;
                }
                var overflow = windowWidth - (leftOffset + newWidth + 20);
                $expandable.css('left', (leftOffset + overflow) + 'px');
            }
        });

        $ml.empty()
          .append($expandToggle)
          .append($expandable);
        // Process any more-less divs within this. These won't be done by the
        // original find, as the original ones will have been obliterated by
        // the more-less process
        $expandable.find('.more-less').each(convert);
    };

    var $widgets = $('.more-less', context);
    $widgets.each(convert);
  };


  return context => {
    setupLessMoreWidgets(context);
  };
})()

export { setupLessMoreWidgets };
