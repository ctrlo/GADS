import { Component } from 'component';
import { setupDisclosureWidgets } from './disclosure-widgets';
import { moreLess } from './more-less';

const MAX_HEIGHT = 50;

/**
 * MoreLessComponent is a class that manages the more/less functionality
 */
class MoreLessComponent extends Component {
    /**
     * Creates an instance of MoreLessComponent.
     * @param {HTMLElement} element The element to attach the component to.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.clearMoreLess();
        this.initMoreLess();
    }

    /**
     * Generates a UUID.
     * @returns {string} A UUID string.
     * @deprecated Please use crypto.randomUUID() instead.
     */
    uuid() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            const r = (Math.random() * 16) | 0,
                v = c == 'x' ? r : (r & 0x3) | 0x8;
            return v.toString(16);
        });
    }

    /**
     * Find the first parent element that is hidden
     * @param {JQuery<HTMLElement>} $elem The jQuery element to check for hidden parents.
     * @returns {JQuery<HTMLElement>|undefined} The first hidden parent element or undefined if no hidden parent is found.
     */
    parentHidden($elem) {
    // Test parent first in case we have reached the root of the DOM, in which
    // case .css() will throw an error on the element
        const $parent = $elem.parent();
        if (!$parent || !$parent.length) {
            return undefined;
        }
        if ($elem.css('display') == 'none') {
            return $elem;
        }
        return this.parentHidden($parent);
    }

    /**
     * Get the actual height of an element.
     * @param {JQuery<HTMLElement>} $elem The jQuery element to measure.
     * @returns {number} The actual height of the element.
     * @description We previously used a plugin for this but its performance was slow when a page had many more-less divs
     * @see https://github.com/dreamerslab/jquery.actual
     */
    getActualHeight($elem) {
        if ($elem.attr('data-actual-height')) {
            // cached heights from previous runs
            return $elem.attr('data-actual-height');
        }

        // If the element is blank then it will have 0 height
        if ($elem.text().trim().length == 0) {
            return 0;
        }

        if ($elem.height()) {
            // Assume element is visible
            return $elem.height();
        }

        // The reason this element is visible could be because of a parent element
        const $parent = this.parentHidden($elem, 0);

        if (!$parent) {
            return;
        }

        // Add a unique identifier to each more-less class, before cloning. Once we
        // measure the height on the cloned elements, we can apply the height as a
        // data value to its real equivalent element using this unique class.
        $parent.find('.more-less').each(function () {
            const $e = $(this);
            $e.addClass('more-less-id-' + crypto.randomUUID());
        });

        // Clone the element and show it to find out its height
        const $clone = $parent
            .clone()
            .attr('id', false)
            .css({ visibility: 'hidden', display: 'block', position: 'absolute' });
        $('body').append($clone);

        // The cloned element could contain many other hidden more-less divs, so do
        // them all at the same time to improve performance
        $clone.find('.more-less').each(function () {
            const $ml = $(this);
            const classList = $ml.attr('class').split(/\s+/);
            $.each(classList, function (index, item) {
                if (item.indexOf('more-less-id') >= 0) {
                    const $toset = $parent.find('.' + item);
                    // Can't use data() as it can't be re-read
                    $toset.attr('data-actual-height', $ml.height());
                }
            });
        });

        $clone.remove();

        return $elem.attr('data-actual-height');
    }

    /**
     * Reinitializes the more/less functionality.
     */
    reInitMoreLess() {
        this.clearMoreLess();
        this.initMoreLess();
    }

    /**
     * Clears the more/less state from the element.
     */
    clearMoreLess() {
        const $ml = $(this.el);

        if ($ml.hasClass('clipped')) {
            const content = $ml.find('.expandable').html();

            $ml
                .html(content)
                .removeClass('clipped');
        }
    }

    /**
     * Initializes the more/less functionality on the element.
     */
    initMoreLess() {
        const $ml = $(this.el);
        const column = $ml.data('column');
        const content = $ml.html();

        moreLess.addSubscriber(this);

        $ml.removeClass('transparent');
        // Element may be hidden (e.g. when rendering edit fields on record page).
        // Actual height may be undefined in the event of errors.
        const ah = this.getActualHeight($ml);
        if (!ah || ah < MAX_HEIGHT) {
            return;
        }
        $ml.addClass('clipped');

        const $expandable = $('<div/>', {
            class: 'expandable popover column-content card card--secundary',
            html: content
        });

        const toggleLabel = 'Show ' + column + ' ⇒';

        const $expandToggle = $('<button/>', {
            class: 'btn btn-sm btn-inverted trigger',
            text: toggleLabel,
            type: 'button',
            'aria-expanded': false,
            'data-expand-on-hover': false,
            'data-label-expanded': 'Hide ' + column,
            'data-label-collapsed': toggleLabel
        });

        $expandToggle.on('toggle', function (e, state) {
            const windowWidth = $(window).width();
            const leftOffset = $expandable.offset().left;
            const minWidth = 400;
            const colWidth = $ml.width();
            const newWidth = colWidth > minWidth ? colWidth : minWidth;
            if (state === 'expanded') {
                $expandable.css('width', newWidth + 'px');
                if (leftOffset + newWidth + 20 < windowWidth) {
                    return;
                }
                const overflow = windowWidth - (leftOffset + newWidth + 20);
                $expandable.css('left', leftOffset + overflow + 'px');
            }
        });

        $ml
            .empty()
            .append($expandToggle)
            .append($expandable);

        setupDisclosureWidgets($ml);

        // Set up the record-popup modal for any curvals in this more-less
        import(/* webpackChunkName: "record-popup" */ '../../record-popup/lib/component')
            .then(({ default: RecordPopupComponent }) => {
                const recordPopupElements = $ml.find('.record-popup');
                recordPopupElements.each((i, el) => {
                    new RecordPopupComponent(el);
                });
            });

    // Process any more-less divs within this. These won't be done by the
    // original find, as the original ones will have been obliterated by
    // the more-less process
    // $expandable.find(".more-less").each(convert);
    }
}

export default MoreLessComponent;
