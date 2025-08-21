// We import Bootstrap because there is an error that throws if we don't (this.collapse is not a function).
/* eslint-disable @typescript-eslint/no-this-alias */
import 'bootstrap';
import { Component } from 'component';
import { logging } from 'logging';
import { initValidationOnField } from 'validation';

/**
 * A SelectWidget is a custom disclosure widget with multi or single options selectable.
 * SelectWidgets can depend on each other; for instance if Value "1" is selected in Widget "A", Widget "B" might not be displayed.
 */
class SelectWidgetComponent extends Component {
    /**
     * Constructor for the SelectWidgetComponent.
     * @param {HTMLElement} element The HTML element that this component is attached to.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.$selectWidget = this.el;
        this.$widget = this.el.find('.form-control');
        this.$trigger = this.$widget.find('[aria-expanded]');
        this.$current = this.el.find('.current');
        this.$available = this.el.find('.available');
        this.$availableItems = this.el.find('.available .answer input');
        this.$moreInfoButtons = this.el.find('.available .answer .btn-js-more-info');
        this.$target = this.el.find('#' + this.$trigger.attr('aria-controls'));
        this.$currentItems = this.$current.find('[data-list-item]');
        this.$answers = this.el.find('.answer');
        this.$fakeInput = null;
        this.$search = this.el.find('.form-control-search');
        this.lastFetchParams = null;
        this.multi = this.el.hasClass('multi');
        this.required = this.el.hasClass('select-widget--required');
        // Give each AJAX load its own ID. If a higher ID has started by the time
        // we get the results, then cancel the current process to prevent
        // duplicate items being added to the dropdown
        this.loadCounter = 0;

        this.initSelectWidget();

        if (this.required) {
            initValidationOnField(this.el);
        }
    }

    /**
     * Initializes the SelectWidget component.
     */
    initSelectWidget() {
        this.updateState();
        if (this.$widget.is('[readonly]')) return;
        this.connect();

        this.$widget.off('click');
        this.$widget.on('click', () => { this.handleWidgetClick(); });

        this.$search.off('blur');
        this.$search.on('blur', (e) => { this.possibleCloseWidget(e); });

        this.$availableItems.off('blur');
        this.$availableItems.on('blur', (e) => { this.possibleCloseWidget(e); });

        this.$moreInfoButtons.off('blur');
        this.$moreInfoButtons.on('blur', (e) => { this.possibleCloseWidget(e); });

        $(document).on('click', (e) => { this.handleDocumentClick(e); });

        $(document).on('keyup',function (e) {
            if (e.key == 'Escape') {
                this.collapse(this.$widget, this.$trigger, this.$target);
            }
        });

        this.$widget.on('.select-widget-value__delete', 'click', function (e) {
            e.preventDefault();
            e.stopPropagation();

            // Uncheck checkbox
            const checkboxId = e.target.parentElement.getAttribute('data-list-item');
            const checkbox = document.getElementById(checkboxId);
            checkbox.checked = false;
            $(checkbox).parent()
                .trigger('click'); // Needed for single-select
            $(checkbox).trigger('change');
        });

        this.$search.off('focus', this.expandWidgetHandler);
        this.$search.on('focus', (e) => { this.expandWidgetHandler(e); });

        this.$search.off('keydown');
        this.$search.on('keydown', (e) => { this.handleKeyDown(e); });

        this.$search.off('keyup');
        this.$search.on('keyup', (e) => { this.handleKeyUp(e); });

        this.$search.off('click');
        this.$search.on('click', (e) => {
            // Prevent bubbling the click event to the $widget (which expands/collapses the widget on click).
            e.stopPropagation();
        });
    }

    /**
     * Handles the click event on the widget.
     */
    handleWidgetClick() {
        if (this.$trigger.attr('aria-expanded') === 'true') {
            this.collapse(this.$widget, this.$trigger, this.$target);
        } else {
            this.expand(this.$widget, this.$trigger, this.$target);
        }
    }

    /**
     * Handles the click event on the document.
     * @param {JQuery.ClickEvent} e The click event triggered on the document.
     */
    handleDocumentClick(e) {
        const clickedOutside = !this.el.is(e.target) && this.el.has(e.target).length === 0;
        if (clickedOutside) {
            this.collapse(this.$widget, this.$trigger, this.$target);
        }
    }

    /**
     * Handle the keyup event on the search input.
     * @param {JQuery.KeyUpEvent} e The keyup event triggered on the search input.
     */
    handleKeyUp(e) {
        const searchValue = $(e.target)
            .val()
            .toLowerCase();
        const self = this;

        this.$fakeInput =
            this.$fakeInput ||
            $('<span>')
                .addClass('form-control-search')
                .css('white-space', 'nowrap');
        this.$fakeInput.text(searchValue);
        this.$search.css('width', this.$fakeInput.insertAfter(this.$search).width() + 100);
        this.$fakeInput.detach();

        if (this.$selectWidget.data('value-selector') == 'typeahead') {
            const url = `/${this.$selectWidget.data(
                'layout-id'
            )}/match/layout/${this.$selectWidget.data('typeahead-id')}`;
            // Debounce the user input, only execute after 200ms if another one
            // hasn't started
            clearTimeout(this.timeout);
            this.$available.find('.spinner').removeAttr('hidden');
            this.timeout = setTimeout(function () {
                self.$available.find('.answer').not('.answer--blank')
                    .each(function () {
                        const $answer = $(this);
                        if (!$answer.find('input:checked').length) {
                            $answer.remove();
                        }
                    });
                self.updateJson(url + '?noempty=1&q=' + searchValue, true);
            }, 200);
        } else {
            // hide the answers that do not contain the searchvalue
            let anyHits = false;
            $.each(this.$answers, function () {
                const labelValue = $(this)
                    .find('label')[0]
                    .innerHTML.toLowerCase();
                if (labelValue.indexOf(searchValue) === -1) {
                    $(this).attr('hidden', '');
                } else {
                    anyHits = true;
                    $(this).removeAttr('hidden', '');
                }
            });

            if (anyHits) {
                this.$available.find('.has-noresults').attr('hidden', '');
            } else {
                this.$available.find('.has-noresults').removeAttr('hidden', '');
            }
        }
    }

    /**
     * Handle the keydown event on the search input.
     * @param {JQuery.KeyDownEvent} e The keydown event triggered on the search input.
     */
    handleKeyDown(e) {
        const key = e.key;

        // If still in search text after previous search and select, ensure that
        // widget expands again to show results
        this.expand(this.$widget, this.$trigger, this.$target);

        switch (key) {
            case 'ArrowUp': // UP
            case 'ArrowDown': // DOWN
            {
                const items = this.$available.find('.answer:not([hidden]) input');
                let nextItem;

                e.preventDefault();

                if (key === 38) {
                    nextItem = items[items.length - 1];
                } else {
                    nextItem = items[0];
                }

                if (nextItem) {
                    $(nextItem).trigger('focus');
                }

                break;
            }
            case 'Enter': // ENTER
            {
                e.preventDefault();

                // Select the first (visible) item
                const firstItem = this.$available.find('.answer:not([hidden]) input').get(0);
                if (firstItem) {
                    $(firstItem)
                        .parent()
                        .trigger('click');
                }

                break;
            }
        }
    }

    /**
     * Handle the event triggered when the widget is expanded.
     * @param {JQuery.TriggeredEvent} e The event triggered when the widget is expanded.
     */
    expandWidgetHandler(e) {
        e.stopPropagation();
        this.expand(this.$widget, this.$trigger, this.$target);
    }

    /**
     * Collapse the select widget.
     * @param {JQuery<HTMLElement>} $widget The widget element.
     * @param {JQuery<HTMLElement>} $trigger The trigger element that expands the widget.
     */
    collapse($widget, $trigger) {
        this.$selectWidget.removeClass('select-widget--open');
        $trigger.attr('aria-expanded', false);

        // Add a small delay when hiding the select widget, to allow IE to also
        // fire the default actions when selecting a radio button by clicking on
        // its label. When the input is hidden on the click event of the label
        // the input isn't actually being selected.
        setTimeout(() => {
            this.$search.val('');
            this.$target.attr('hidden', '');
            this.$answers.removeAttr('hidden');
        }, 50);
    }

    /**
     * Update the state of the select widget based on the current items.
     */
    updateState() {
        const $visible = this.$current.children('[data-list-item]:not([hidden])');

        this.$current.toggleClass('empty', $visible.length === 0);
    }

    /**
     * Possible close the widget based on focus change.
     * @param {JQuery.TriggeredEvent} e The event triggered when the widget might need to be closed.
     */
    possibleCloseWidget(e) {
        const newlyFocussedElement = e.relatedTarget || document.activeElement;

        if (
            !this.$selectWidget.find(newlyFocussedElement).length &&
            newlyFocussedElement &&
            !$(newlyFocussedElement).is('.modal, .page, body') &&
            this.$selectWidget.get(0).parentNode !== newlyFocussedElement
        ) {
            this.collapse(this.$widget, this.$trigger, this.$target);
        }
    }

  connectMulti() {
        const self = this;
        return function () {
            const $item = $(this);
            const itemId = $item.data('list-item');
            const $associated = $('#' + itemId);

            $associated.off('change');
            $associated.on('change', (e) => {
                if ($(e.target).prop('checked')) {
                    $item.removeAttr('hidden');
                } else {
                    $item.attr('hidden', '');
                }
                self.updateState();
            });

            $associated.off('keydown');
            $associated.on('keydown', function (e) {
                const key = e.key;

                switch (key) {
                    case 'ArrowUp': // UP
                    case 'ArrowDown': // DOWN
                    {
                        const currentIndex = self.$answers.index($associated.closest('.answer'));
                        let nextItem;

                        e.preventDefault();

                        if (key === 38) {
                            nextItem = self.$answers[currentIndex - 1];
                        } else {
                            nextItem = self.$answers[currentIndex + 1];
                        }

                        if (nextItem) {
                            $(nextItem)
                                .find('input')
                                .trigger('focus');
                        }

                        break;
                    }
                    case 'Enter':
                    {
                        e.preventDefault();
                        $(this).trigger('click');
                        break;
                    }
                }
            });
        };
    }

    /**
     * Connects the single-select items to their associated checkboxes.
     */
    connectSingle() {
        const self = this;

        this.$currentItems.each((_, item) => {
            const $item = $(item);
            const itemId = $item.data('list-item');
            const $associated = $('#' + itemId);

            $associated.off('click');
            $associated.on('click', function (e) {
                e.stopPropagation();
            });

            $associated.off('change');
            $associated.on('change', function () {
                // First hide all items in the drop-down display
                self.$currentItems.each((_, currentItem) => {
                    $(currentItem).attr('hidden', '');
                });
                // Then show the one selected
                if ($associated.prop('checked')) {
                    $item.removeAttr('hidden');
                }
                // Update state so as to show "select option" default text for nothing
                // selected
                self.updateState();
            });

            $associated.parent().off('keypress');
            $associated.parent().on('keypress', (e) => {
                // KeyCode Enter or Spacebar
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    $(e.target).parent()
                        .trigger('click');
                }
            });

            $associated.parent().off('click');
            $associated.parent().on('click', () => {
                // Need to collapse on click (not change) otherwise drop-down will
                // collapse when changing using the keyboard
                this.collapse(this.$widget, this.$trigger, this.$target);
            });
        });
    }

    /**
     * Connects the select widget items to their associated checkboxes.
     */
    connect() {
        if (this.multi) {
            this.$currentItems.each(this.connectMulti());
        } else {
            this.connectSingle();
        }
    }

    /**
     * Get the current list item for the select widget.
     * @param {boolean} multi Is the select widget multi-select?
     * @param {JQuery<HTMLElement>} field The field name for the select widget.
     * @param {number} value_id The ID of the value.
     * @param {string} value_text The text of the value.
     * @param {string} value_html The HTML representation of the value.
     * @param {boolean} checked Is the value checked?
     * @returns {JQuery<HTMLElement>} The current list item as a jQuery object.
     */
    currentLi(multi, field, value_id, value_text, value_html, checked) {
        if (multi && !value_id) {
            return $('<li class="none-selected">blank</li>');
        }

        const valueId = value_id ? field + '_' + value_id : field + '__blank';
        const className = value_id ? '' : 'current__blank';
        const deleteButton = '<button type="button" class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times</button>';
        const $li = $(
            '<li ' +
            (checked ? '' : 'hidden') +
            ' data-list-item="' +
            valueId +
            '" class="' +
            className +
            '"><span class="widget-value__value">' +
            '</span>' +
            deleteButton +
            '</li>'
        );
        $li.data('list-text', value_text);
        $li.data('list-id', value_id);
        $li.find('span').html(value_html);
        return $li;
    }

    /**
     * Get the available list item for the select widget.
     * @param {boolean} multi Is the select widget multi-select?
     * @param {JQuery<HTMLElement>} field The field name for the select widget.
     * @param {number} value_id The ID of the value.
     * @param {string} value_text The text of the value.
     * @param {string} label The label for the value.
     * @param {boolean} checked Is the value checked?
     * @returns {JQuery<HTMLElement>} The available list item as a jQuery object.
     */
    availableLi(multi, field, value_id, value_text, label, checked) {
        if (this.multi && !value_id) {
            return null;
        }

        const valueId = value_id ? field + '_' + value_id : field + '__blank';
        const classNames = value_id ? 'answer' : 'answer answer--blank';

        // Add space at beginning to keep format consistent with that in template
        const detailsButton =
            ' <div class="details">' +
            '<button type="button" class="btn btn-small btn-default btn-js-more-info" data-record-id="' + value_id +
            '" aria-describedby="lbl-' + valueId +
            '" data-target="' + this.el.data('details-modal') + // TODO: get id of modal
            '" data-toggle="modal">' +
            'Details' +
            '</button>' +
            '</div>';

        const $li = $(
            '<li class="' +
            classNames +
            '">' +
            '<div class="control">' +
            '<div class="' +
            (multi ? 'checkbox' : 'radio-group__option') +
            '">' +
            '<input id="' +
            valueId +
            '" type="' +
            (multi ? 'checkbox' : 'radio') +
            '" name="' +
            field +
            '" ' +
            (checked ? ' checked' : '') +
            (this.required && !this.multi ? ' required aria-required="true"' : '') +
            ' value="' +
            (value_id || '') +
            '" class="' +
            (multi ? '' : 'visually-hidden') +
            '" aria-labelledby="lbl-' +
            valueId +
            '"> ' + // Add space to keep spacing consistent with templates
            '<label id="lbl-' +
            valueId +
            '" for="' +
            valueId +
            '">' + label +
            '</label>' +
            '</div>' +
            '</div>' +
            (value_id ? detailsButton : '') +
            '</li>'
        );
        $li.data('list-text', value_text);
        $li.data('list-id', value_id);
        return $li;
    }

    /**
     * Update the JSON data for the select widget.
     * @param {string} url The URL to fetch the JSON data from.
     * @param {boolean} typeahead Whether the update is for typeahead functionality.
     */
    updateJson(url, typeahead) {
    const formData = {"csrf_token": $('body').data('csrf')};
    this.loadCounter++
    const self = this;
    const myLoad = this.loadCounter // ID of this process
    this.$available.find(".spinner").removeAttr("hidden")
    const currentValues = this.$available
      .find("input:checked")
      .map(function() {
        return parseInt($(this).val());
      })
      .get()

    // Remove existing items if needed, now that we have found out which ones are selected
    if (!typeahead) {
      this.$available.find(".answer").remove()
    }

    const field = this.$selectWidget.data("field")
    // If we cancel this particular loop, then we don't want to remove the
    // spinner if another one has since started running
    let hideSpinner = true
    $.ajax(url, { method: "POST", data: formData}).done((data)=>{
      data = fromJson(data)
      if (data.error === 0) {
        if (myLoad != this.loadCounter) { // A new one has started running
          hideSpinner = false // Don't remove the spinner on completion
          return
        }
        
                if (typeahead) {
                    // Need to keep currently selected item
                    this.$currentItems.filter(':hidden').remove();
                } else {
                    this.$currentItems.remove();
                }

                const checked = currentValues.includes(NaN);
                if (this.multi) {
                    this.$search
                        .parent()
                        .prevAll('.none-selected')
                        .remove(); // Prevent duplicate blank entries
                    this.$search
                        .parent()
                        .before(this.currentLi(this.multi, field, null, '', 'blank', checked));
                    this.$available.append(this.availableLi(this.multi, field, null, '', 'blank', checked));
                }

                $.each(data.records, (recordIndex, record) => {
                    const checked = currentValues.includes(record.id);
                    if (!typeahead || (typeahead && !checked)) {
                        this.$search
                            .parent()
                            .before(
                                this.currentLi(this.multi, field, record.id, record.label, record.html, checked)
                            )
                            .before(' '); // Ensure space between elements
                        this.$available.append(
                            this.availableLi(this.multi, field, record.id, record.label, record.html, checked)
                        );
                    }
                });

                this.$currentItems = this.$current.find('[data-list-item]');
                this.$available = this.$selectWidget.find('.available');
                this.$availableItems = this.$selectWidget.find('.available .answer input');
                this.$moreInfoButtons = this.$selectWidget.find(
                    '.available .answer .btn-js-more-info'
                );
                this.$answers = this.$selectWidget.find('.answer');

                this.updateState();
                this.connect();

                this.$availableItems.on('blur', (e) => { this.possibleCloseWidget(e); });
                this.$moreInfoButtons.on('blur', (e) => { this.possibleCloseWidget(e); });
                this.$moreInfoButtons.each((_, button) => {
                    import(/* webpackChunkName: "more-info-button" */ '../../../button/lib/more-info-button')
                        .then(({ default: MoreInfoButton }) => { new MoreInfoButton(button); }
                        );
                });

            } else {
                const errorMessage =
                    data.error === 1 ? data.message : 'Oops! Something went wrong.';
                const errorLi = $(
                    '<li class="answer answer--blank alert alert-danger d-flex flex-row justify-content-start"><span class="control"><label>' +
                    errorMessage +
                    '</label></span></li>'
                );
                this.$available.append(errorLi);
            }
        })
            .fail(function (jqXHR, textStatus, textError) {
                const errorMessage = 'Oops! Something went wrong.';
                logging.error(
                    'Failed to make request to ' +
                    url +
                    ': ' +
                    textStatus +
                    ': ' +
                    textError
                );
                const errorLi = $(
                    '<li class="answer answer--blank alert alert-danger"><span class="control"><label>' +
                    errorMessage +
                    '</label></span></li>'
                );
                self.$available.append(errorLi);
            })
            .always(function () {
                if (hideSpinner) {
                    self.$available.find('.spinner').attr('hidden', '');
                }
            });
    }

    /**
     * Fetch options for the select widget based on linked fields.
     * @throws Will throw an error if the filter fields are not a valid array.
     */
    fetchOptions() {
        const filterEndpoint = this.$selectWidget.data('filter-endpoint');
        const filterFields = this.$selectWidget.data('filter-fields');
        const submissionToken = this.$selectWidget.data('submission-token');

        if (!Array.isArray(filterFields)) {
            throw 'Invalid data-filter-fields found. It should be a proper JSON array of fields.';
        }

        // Collect values of linked fields
        const values = ['submission-token=' + submissionToken];
        $.each(filterFields, function(_, field) {

            $('input[name=' + field + ']').each(function(_, input) {
                const $input = $(input);

                switch ($input.attr('type')) {
                    case 'number':
                        values.push(field + '=' + $input.val());
                        break;
                    case 'text':
                        values.push(field + '=' + $input.val());
                        break;
                    case 'radio':
                        if (input.checked) {
                            values.push(field + '=' + $input.val());
                        }
                        break;
                    case 'checkbox':
                        if (input.checked) {
                            values.push(field + '=' + $input.val());
                        }
                        break;
                    case 'hidden': // Tree values stored as hidden field
                        values.push(field + '=' + $input.val());
                        break;
                }
            });
        });

        // Bail out if the options haven't changed
        const fetchParams = values.join('&');

        if (this.lastFetchParams === fetchParams) {
            return;
        }
        this.lastFetchParams = null;

        this.updateJson(filterEndpoint + '?' + fetchParams);
        this.lastFetchParams = fetchParams;
    }

    /**
     * Expand the select widget to show available options.
     * @param {JQuery<HTMLElement>} $widget The widget element.
     * @param {JQuery<HTMLElement>} $trigger The trigger element that expands the widget.
     * @param {JQuery<HTMLElement>} $target The target element that contains the available options.
     */
    expand($widget, $trigger, $target) {
        if ($trigger.attr('aria-expanded') === 'true') {
            return;
        }
        this.$selectWidget.addClass('select-widget--open');
        this.$available.find('.spinner').attr('hidden', '');
        $trigger.attr('aria-expanded', true);

        if (
            this.$selectWidget.data('filter-endpoint') &&
            this.$selectWidget.data('filter-endpoint').length
        ) {
            try {
                this.fetchOptions();
            } catch (e) {
                logging.error(e);
            }
        }

        const widgetTop = $widget.offset().top;
        const widgetBottom = widgetTop + $widget.outerHeight();
        const viewportTop = $(window).scrollTop();
        const viewportBottom = viewportTop + $(window).height() - 60;
        const minimumRequiredSpace = 200;
        const fitsBelow = widgetBottom + minimumRequiredSpace < viewportBottom;
        const fitsAbove = widgetTop - minimumRequiredSpace > viewportTop;
        const expandAtTop = fitsAbove && !fitsBelow;
        $target.toggleClass('available--top', expandAtTop);
        $target.removeAttr('hidden');

        if (this.$search.get(0) !== document.activeElement) {
            this.$search.trigger('focus');
        }
    }
}

export default SelectWidgetComponent;
