import { ElementOrJQueryElement, addClass, hideElement, removeClass, showElement, stopPropagation } from "util/common";

/**
 * Interface containing the options for the FileDrag class.
 */
interface FileDragOptions {
    allowMultiple?: boolean;
    // Don't know if this is really needed - can use window.test for jest. Keep in for now in case it is needed.
    debug?: boolean;
}

/**
 * Class for handling file drag and drop events.
 */
class FileDrag {
    private el: JQuery<HTMLElement>;
    private dropZone: JQuery<HTMLElement>;
    // for testing
    protected dragging: boolean = false;

    /**
     * Constructor for the FileDrag class.
     * @param element - The element to attach the file drag and drop events to.
     * @param options - The options for the FileDrag class.
     * @param onDrop - The function to call when a file is dropped.
     */
    constructor(element: ElementOrJQueryElement, private options: FileDragOptions = {}, private onDrop?: (files: FileList | File) => void) {
        if (options.debug) console.log('FileDrag', element, options);
        this.el = element instanceof HTMLElement ? $(element) : element;
        this.initElements()
        this.initDocumentEvents();
        this.initElementEvents();
    }

    /**
     * Initializes the element events for the FileDrag class.
     */
    initElementEvents() {
        if (this.options.debug || window.test) console.log('initElementEvents');
        this.dropZone.on('dragenter', (e) => {
            if (!this.dragging) return;
            addClass(this.dropZone, 'dragging');
            stopPropagation(e);
        });
        this.dropZone.on('dragleave', (e) => {
            if (!this.dragging) return;
            removeClass(this.dropZone, 'dragging');
            stopPropagation(e);
        });
        this.dropZone.on('drop', (e) => {
            if (!this.dragging) return;
            this.dragging = false;
            removeClass(this.el, 'dragging');
            hideElement($('.drop-zone'));
            showElement($('[data-draggable="true"]'));
            if (this.options.debug || window.test) console.log(e.originalEvent.dataTransfer.files);
            showElement(this.el);
            if(this.options.debug || window.test) console.log(e.originalEvent.dataTransfer.files);
            if (this.options.allowMultiple) {
                this.onDrop(e.originalEvent.dataTransfer.files);
            } else {
                this.onDrop(e.originalEvent.dataTransfer.files[0]);
            }
            $(document).trigger('drop');
            stopPropagation(e);
        });
    }

    /**
     * Initializes the document events for the FileDrag class.
     */
    initDocumentEvents() {
        if (this.options.debug || window.test) console.log('initDocumentEvents');
        $(document).on('dragenter', (e) => {
            if (this.dragging) return;
            this.dragging = true;
            hideElement(this.el);
            showElement(this.dropZone);
        });
        $(document).on('dragleave', (e) => {
            if (!this.dragging) return;
            if (e.originalEvent.pageX != 0 || e.originalEvent.pageY != 0) {
                return false;
            }
            this.dragging = false;
            hideElement(this.dropZone);
            showElement(this.el);
        });
        $(document).on('drop', (e) => {
            if (!this.dragging) return;
            this.dragging = false;
            hideElement(this.dropZone);
            showElement(this.el);
            stopPropagation(e);
        })
        $(document).on('dragover', (e) => {
            if (!this.dragging) return;
            stopPropagation(e);
        });
    }

    /**
     * Initializes the elements for the FileDrag class.
     */
    initElements() {
        if (this.options.debug || window.test) console.log('initElements');
        this.el.data('draggable', 'true');
        this.dropZone = $('<div class="drop-zone">Drop files here</div>');
        const error = $('<div class="upload__error">Error</div>');
        hideElement(error)
        const parent = this.el.parent();
        parent.append(this.dropZone);
        parent.append(error);
        hideElement(this.dropZone);
    }
}

export default FileDrag;
