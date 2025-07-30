import { Component } from 'component';
import { initValidationOnField } from 'validation';

const SELECT_PLACEHOLDER = 'select__placeholder';
const SELECT_MENU_ITEM_ACTIVE = 'select__menu-item--active';
const SELECT_MENU_ITEM_HOVER = 'select__menu-item--hover';

/**
 * Select component that handles custom select functionality
 */
class SelectComponent extends Component {
    /**
     * Create a new SelectComponent instance
     * @param {HTMLElement} element The select element
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.toggleButton = this.el.find('.select__toggle');
        this.input = this.el.find('input');
        this.menu = this.el.find('.select__menu');
        this.options = this.el.find('.select__menu-item');
        this.optionChecked = '';
        this.optionHoveredIndex = -1;
        this.optionsCount = this.options.length;
        this.isSelectReveal = this.el.hasClass('select--reveal');
        this.initSelect(this.el);

        if (this.el.hasClass('select--required')) {
            initValidationOnField(this.el);
        }
    }

    /**
     * Intializes the select
     */
    initSelect() {
        if (!this.options) {
            return;
        }

        // Bind event handlers
        this.options.on('click', (ev) => { this.handleClick(ev); });
        this.input.on('change', (ev) => { this.handleChange(ev); });
        this.el.on('show.bs.dropdown', () => { this.handleOpen(); });

        if (this.input.val()) {
            this.input.trigger('change');
        }
    }

    /**
     * Add an option to the select menu
     * @param {string} name The name of the option to add
     * @param {string} value The value of the option to add
     */
    addOption(name, value) {
        const newOption = document.createElement('li');

        newOption.classList.add('select__menu-item');
        newOption.setAttribute('role', 'option');
        newOption.setAttribute('aria-selected', 'false');
        newOption.setAttribute('data-id', name);
        newOption.setAttribute('data-value', value);
        newOption.innerHTML = name;

        this.menu.append(newOption);
        this.bindOptionHandler(newOption);
        this.options = this.el.find('.select__menu-item');
    }

    /**
     * Remove an option from the select menu
     * @param {string} value The value of the option to remove
     */
    removeOption(value) {
        this.options.each((i, option) => {
            if (parseInt(option.dataset.value) === value) {
                option.remove();
            }
        });
    }

    /**
     * Update an option in the select menu
     * @param {string} name The name of the option to update
     * @param {string} value The value of the option to update
     */
    updateOption(name, value) {
        this.options.each((i, option) => {
            if (parseInt(option.dataset.value) === value) {
                option.setAttribute('data-id', name);
                option.innerHTML = name;
            }
        });
    }

    /**
     * Bind a click handler to an option
     * @param {HTMLElement} option The option element to bind the click handler to
     */
    bindOptionHandler(option) {
        $(option).on('click', (ev) => { this.handleClick(ev); });
    }

    /**
     * Handles the opening of the select
     */
    handleOpen() {
        this.el.on('keydown', (ev) => { this.supportKeyboardNavigation(ev); });
    }

    /**
     * Handles the closing of the select
     * @param {JQuery.TriggeredEvent} ev The event that triggered the close
     */
    handleClose(ev) {
        this.el.dropdown('hide');
        ev.stopPropagation();
        this.el.off('keydown');
    }

    /**
     * Handles a change event of the (hidden) input
     * @param {JQuery.ChangeEvent} ev The event that triggered the change
     */
    handleChange(ev) {
        const value = $(ev.target).val();

        if (value === '') {
            this.resetSelect();
        } else {
            this.options.each((i, option) => {
                if ($(option).data('value')
                    .toString() === value) {
                    this.updateChecked($(option));
                    if (this.isSelectReveal) {
                        this.revealInstance($(option));
                    }
                }
            });
        }
    }

    /**
     * Handles a click event on one of the options
     * @param {JQuery.ClickEvent} ev The event that triggered the click
     */
    handleClick(ev) {
        const option = $(ev.target);
        const value = option.data('value');
        const revealID = option.data('reveal_id');

        this.input
            .val(value)
            .trigger('change');

        if (revealID !== undefined) {
            this.input.attr('data-reveal_id', revealID);
        }

        this.updateChecked($(option));

        if (this.isSelectReveal) {
            this.revealInstance($(option));
        }

        this.toggleButton.trigger('focus');
    }

    /**
     * Reveals the instance associated with the clicked option
     * @param {JQuery<HTMLElement>} $option The option that was clicked
     */
    revealInstance($option) {
        const arrSelectRevealInstances = $(`.select-reveal--${this.input.attr('id')} > .select-reveal__instance`);
        let instanceID = '';

        if ($option.data('reveal_id') !== undefined) {
            instanceID = `#${this.input.attr('id')}_${$option.data('reveal_id')}`;
        } else {
            instanceID = `#${this.input.attr('id')}_${$option.data('value')}`;
        }

        arrSelectRevealInstances.each((i, selectRevealInstance) => {
            $(selectRevealInstance).hide();
            this.disableFields(selectRevealInstance, true);
        });

        $(instanceID).show();
        this.disableFields($(instanceID), false);
    }

    /**
     * Enable or disable fields within a container
     * @param {HTMLElement} container The container element that holds the fields to disable
     * @param {boolean} bDisable True to disable the fields, false to enable them
     */
    disableFields(container, bDisable) {
        const $fields = $(container).find('input, textarea');

        if (bDisable) {
            $fields.prop('disabled', true);
        } else {
            $fields.removeAttr('disabled');
        }
    }

    /**
     * Updates the hovered option
     * @param {number} newIndex The index of the new hovered option
     */
    updateHovered(newIndex) {
        const prevOption = this.options[this.optionHoveredIndex];
        const option = this.options[newIndex];

        if (prevOption) {
            prevOption.classList.remove(SELECT_MENU_ITEM_HOVER);
        }
        if (option) {
            option.classList.add(SELECT_MENU_ITEM_HOVER);
        }

        this.optionHoveredIndex = newIndex;
    }

    /**
     * Updates the checked option
     * @param {HTMLElement} option The option element to update
     */
    updateChecked(option) {
        const value = $(option).data('value');
        const text = $(option).html();

        this.toggleButton.find('span').html(text);
        this.toggleButton.find('span').removeClass(SELECT_PLACEHOLDER);

        this.options.removeClass(SELECT_MENU_ITEM_ACTIVE);
        this.options.attr('aria-selected', false);

        $(option).addClass(SELECT_MENU_ITEM_ACTIVE);
        $(option).attr('aria-selected', true);

        this.optionChecked = value;
    }

    /**
     * Handles the keyboard events for navigation within the select menu
     * @param {JQuery.KeyDownEvent} ev The keyboard event
     */
    supportKeyboardNavigation(ev) {
    // press down -> go next
        if (ev.key === 'ArrowDown' && this.optionHoveredIndex < this.optionsCount - 1) {
            ev.preventDefault(); // prevent page scrolling
            this.updateHovered(this.optionHoveredIndex + 1);
        }

        // press up -> go previous
        if (ev.key === 'ArrowUp' && this.optionHoveredIndex > 0) {
            ev.preventDefault(); // prevent page scrolling
            this.updateHovered(this.optionHoveredIndex - 1);
        }

        // press Enter or space -> select the option
        if (ev.key === 'Enter' || ev.key === ' ') {
            ev.preventDefault();

            const option = this.options[this.optionHoveredIndex];
            const value = option && $(option).data('value');

            if (value) {
                this.input
                    .val(value)
                    .trigger('change');
            }

            this.handleClose(ev);
        }

        // press ESC -> close selectCustom
        if (ev.key === 'Escape') {
            this.handleClose(ev);
        }
    }

    /**
     * Reset the select to it's initial state
     */
    resetSelect() {
        const placeholder = this.input[0].placeholder;

        this.toggleButton.find('span').html(placeholder);
        this.toggleButton.find('span').addClass(SELECT_PLACEHOLDER);
        this.options.removeClass(SELECT_MENU_ITEM_ACTIVE);
        this.options.attr('aria-selected', false);
        this.input.removeAttr('value');
        this.input.removeAttr('data-restore-value');
    }
}

export default SelectComponent;
