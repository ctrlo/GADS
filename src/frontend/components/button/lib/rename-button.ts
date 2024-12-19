import {createElement} from "util/domutils";

/**
 * Event fired when the file is renamed
 */
interface RenameEvent extends JQuery.Event {
  /**
   * The button clicked to fire the rename event
   */
  target: HTMLButtonElement;
  /**
   * The old file name
   */
  oldName: string;
  /**
   * The new file name
   */
  newName: string;
}

declare global {
  interface JQuery<TElement = HTMLElement> {
    /**
     * Create a rename button
     */
    renameButton(): JQuery<TElement>;

    /**
     * Handle the rename event
     * @param { RenameEvent } events The event name
     * @param { 'rename' } handler The event handler
     * @template {HTMLElement} TElement The element type
     * @returns {JQuery<TElement>} the JQuery element
     */
    on(events: 'rename', handler: (ev: RenameEvent) => void): JQuery<TElement>
  }
}

/**
 * Rename button class
 */
class RenameButton {
  private readonly dataClass = 'rename-button';
  private value: string;

  /**
   * Attach event to button
   * @param {HTMLButtonElement} button Button to attach the event to
   */
  constructor(button: HTMLButtonElement) {
    const $button = $(button);
    if ($button.data(this.dataClass) === 'true') return;
    const data = $button.data('fieldId');
    $button.on('click', (ev) => this.renameClick(data, ev));
    $button.data(this.dataClass, 'true');
    this.createElements($button, data);
  }

  /**
   * Create the relevant elements in order to perform the rename
   * @param {JQuery<HTMLButtonElement>} button The button element that shall trigger the rename
   * @param {string | number} id The file ID to trigger the rename for
   */
  private createElements(button: JQuery<HTMLButtonElement>, id: string | number) {
    if (!id) throw new Error("File ID is null or empty");
    if (!button || button.length < 1) throw new Error("Button element is null or empty")
    const fileId = id as number ?? parseInt(id.toString());
    if (!fileId) throw new Error("Invalid file id!");
    button.closest(".row")
      .append(
        createElement('div', {classList: ['col', 'align-content-center']})
          .append(
            createElement("input", {
              type: 'text',
              id: `file-rename-${fileId}`,
              classList: ['input', 'input--text', 'form-control', 'hidden'],
              ariaHidden: 'true'
            })
          )
      ).append(
      createElement('div', {classList: ['col', 'align-content-center']})
        .append(
          createElement("button", {
            id: `rename-confirm-${fileId}`,
            type: 'button',
            textContent: 'Rename',
            ariaHidden: 'true',
            classList: ['btn', 'btn-small', 'btn-default', 'hidden']
          }).on('click', (ev: JQuery.ClickEvent) => {
            ev.preventDefault();
            this.renameClick(typeof (id) === 'string' ? parseInt(id) : id, ev);
          }),
          createElement("button", {
            id: `rename-cancel-${fileId}`,
            type: 'button',
            textContent: 'Cancel',
            ariaHidden: 'true',
            classList: ['btn', 'btn-small', 'btn-danger', 'hidden']
          })
        )
    );
  }

  /**
   * Perform click event
   * @param {number} id The id of the field
   * @param {JQuery.ClickEvent} ev The event object
   */
  private renameClick(id: number, ev: JQuery.ClickEvent) {
    ev.preventDefault();
    const $current = $(`#current-${id}`);
    const original = $current
      .text()
      .split('.')
      .slice(0, -1)
      .join('.');
    $current
      .addClass('hidden')
      .attr('aria-hidden', 'true');
    $(`#file-rename-${id}`)
      .removeClass('hidden')
      .attr('aria-hidden', null)
      .trigger('focus')
      .val(original)
      .on('keydown', (e) => this.renameKeydown(id, $(ev.target), e))
      .on('blur', (e) => {
        this.value = (e.target as HTMLInputElement)?.value;
      })
    $(`#rename-confirm-${id}`)
      .removeClass('hidden')
      .attr('aria-hidden', null)
      .on('click', () => {
        this.triggerRename(id, ev.target)
      });
    $(`#rename-cancel-${id}`)
      .removeClass('hidden')
      .attr('aria-hidden', null)
      .on('click', () => {
        const e = $.Event('keydown', {key: 'Escape', code: 27});
        $(`#file-rename-${id}`).trigger(e);
      })
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
      this.hideRenameControls(id, button);
    }
  }

  /**
   * Rename blur event
   * @param {number} id The id of the field
   * @param {JQuery<HTMLButtonElement>} button The button that was clicked
   */
  private triggerRename(id: number, button: JQuery<HTMLButtonElement>) {
    let $current = $(`#current-${id}`);
    const previousValue = $current.text();
    const extension = '.' + previousValue.split('.').pop();
    const newName = this.value.endsWith(extension) ? this.value : this.value + extension;
    if (newName === '' || newName === previousValue) return;
    $current.text(newName);
    const event = $.Event('rename', {oldName: previousValue, newName, target: button});
    $(button).trigger(event);
    this.hideRenameControls(id, button);
  }

  private hideRenameControls(id: number, button: JQuery<HTMLButtonElement>) {
    $(`#current-${id}`).removeClass('hidden').attr('aria-hidden', 'false');
    $(`#file-rename-${id}`)
      .addClass('hidden')
      .attr('aria-hidden', 'true')
      .off('blur');
    $(`#rename-confirm-${id}`)
      .addClass('hidden')
      .attr('aria-hidden', 'true')
      .off('click');
    $(`#rename-cancel-${id}`)
      .addClass('hidden')
      .attr('aria-hidden', null)
      .off('click');
    $(button).removeClass('hidden').attr('aria-hidden', 'false');
  }
}

(function ($) {
  $.fn.renameButton = function () {
    return this.each(function (_: unknown, el: HTMLButtonElement) {
      new RenameButton(el);
    });
  };
})(jQuery);

export {RenameEvent};
