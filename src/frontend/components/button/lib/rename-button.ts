declare global {
    interface JQuery<TElement = HTMLElement> {
        /**
         * Create a rename button
         */
        renameButton(): JQuery<TElement>;
    }
}

interface RenameEvent extends JQuery.Event {
    target: HTMLButtonElement;
    newName: string;
}

class RenameButton {
    private readonly dataClass = 'rename-button';

    /**
     * Attach event to button
     * @param {HTMLButtonElement} button Button to attach the event to
     * @param {()=>void} onBlur Function to call when the input loses focus
     */
    constructor(button: HTMLButtonElement) {
        const $button = $(button);
        if($button.data(this.dataClass) === 'true') return;
        const data = $button.data('fieldId');
        $button.on('click', (ev) => this.renameClick(data, ev));
        $button.data(this.dataClass, 'true');
    }

    /**
     * Perform click event
     * @param {number} id The id of the field
     * @param {JQuery.ClickEvent} ev The event object 
     */
    private renameClick(id: number, ev: JQuery.ClickEvent) {
        ev.preventDefault();
        const mev = ev;
        $(`#current-${id}`)
            .addClass('hidden')
            .attr('aria-hidden', 'true');
        $(`#file-rename-${id}`)
            .removeClass('hidden')
            .attr('aria-hidden', 'false')
            .trigger('focus')
            .val($(`#current-${id}`).text().split('.').slice(0, -1).join('.'))
            .on('keydown', (ev) => this.renameKeydown(id, mev.target, ev))
            .on('blur', (ev) => this.renameBlur(id, mev.target, ev));
        $(ev.target).addClass('hidden').attr('aria-hidden', 'true');
    }

    /**
     * Rename keydown event
     * @param {number} id The id of the field
     * @param {JQuery<HTMLButtonElement>} button The button that was clicked
     * @param {JQuery.KeyDownEvent} ev The keydown event
     */
    private renameKeydown(id: number, button: JQuery<HTMLButtonElement>, ev: JQuery.KeyDownEvent) {
        if (ev.key === 'Escape') {
            ev.preventDefault();
            $(`#current-${id}`)
                .removeClass('hidden')
                .attr('aria-hidden', 'false');
            $(`#file-rename-${id}`)
                .addClass('hidden')
                .attr('aria-hidden', 'true')
                .off('blur');
            $(button).removeClass('hidden').attr('aria-hidden', 'false');
        } else if (ev.key === 'Enter') {
            $(ev.target).trigger('blur');
        }
    }

    /**
     * Rename blur event
     * @param {number} id The id of the field
     * @param {JQuery<HTMLButtonElement>} button The button that was clicked
     * @param {JQuery.BlurEvent} ev The blur event
     */
    private renameBlur(id: number, button: JQuery<HTMLButtonElement>, ev: JQuery.BlurEvent) {
        try {
            const previousValue = $(`#current-${id}`).text();
            const extension = '.' + previousValue.split('.').pop();
            const newName = $(ev.target).val().endsWith(extension) ? $(ev.target).val() : $(ev.target).val() + extension;
            if (newName === '' || newName === previousValue) return;
            $(`#current-${id}`).text(newName);
            const event = $.Event('rename', { newName, target: button });
            $(button).trigger(event);
        } finally {
            $(`#current-${id}`).removeClass('hidden').attr('aria-hidden', 'false');
            $(`#file-rename-${id}`)
                .addClass('hidden')
                .attr('aria-hidden', 'true')
                .off('blur');
            $(button).removeClass('hidden').attr('aria-hidden', 'false');
        }
    }
}

(function ($) {
    $.fn.renameButton = function () {
        return this.each(function (_: unknown, el: HTMLButtonElement) {
            new RenameButton(el);
        });
    };
})(jQuery);

export { RenameEvent };
