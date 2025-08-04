import { hideElement, showElement } from 'util/common';

/**
 * FileDragOptions interface to define options for the FileDrag class.
 */
export interface FileDragOptions {
    /**
     * Whether to allow multiple files to be dropped.
     * @default false
     * @type {boolean}
     */
    allowMultiple?: boolean;
    /**
     * Whether to enable debug mode for logging.
     * @default false
     * @type {boolean}
     */
    debug?: boolean;
}

/**
 * FileDrag class to handle drag and drop file uploads.
 * @template T The type of the HTML element to be used for drag and drop.
 */
class FileDrag<T extends HTMLElement = HTMLElement> {
    private el: JQuery<T>;
    private dropZone: JQuery<HTMLElement>;
    // for testing
    protected dragging: boolean = false;

    /**
     * Creates an instance of FileDrag.
     * @param {T} element The HTML element to attach the drag and drop functionality to.
     * @param {FileDragOptions} options The options for the FileDrag instance.
     * @param {(FileList | File)} onDrop Callback function to be called when files are dropped.
     */
    constructor(element: T, private options: FileDragOptions = {}, private onDrop: (files: File, index?: number, length?:number) => void) {
        if (options.debug) console.log('FileDrag', element, options);
        this.el = $(element);
        this.initElements();
        this.initDocumentEvents();
        this.initElementEvents();
    }

    /**
     * Initializes the events for the drop zone elements.
     */
    initElementEvents() {
        if (this.options.debug) console.log('initElementEvents');
        this.dropZone.on('dragenter', (e) => {
            if (!this.dragging) return;
            if(!this.dropZone.hasClass('dragging')) this.dropZone.addClass('dragging');
            e.preventDefault();
        });
        this.dropZone.on('dragleave', (e) => {
            if (!this.dragging) return;
            if(this.dropZone.hasClass('dragging')) this.dropZone.removeClass('dragging');
            e.preventDefault();
        });
        this.dropZone.on('drop', (e) => {
            e.preventDefault();
            if (!this.dragging) return;
            this.dragging = false;
            if(this.el.hasClass('dragging')) this.el.removeClass('dragging');
            hideElement($('.drop-zone'));
            showElement($('[data-draggable="true"]'));
            if (this.options.debug) console.log(e.originalEvent.dataTransfer.files);
            showElement(this.el);
            console.log(e.originalEvent.dataTransfer.files);
            if (this.options.allowMultiple) {
                // For some reason the function will not accept a FileList, so we convert it to an array
                const files = Array.from(e.originalEvent.dataTransfer.files);
                files.forEach((file, index) => {
                    this.onDrop(file, index, files.length);
                });
            } else {
                this.onDrop(e.originalEvent.dataTransfer.files[0]);
            }
            $(document).trigger('drop');
        });
    }

    /**
     * Initializes the document-wide drag and drop events.
     */
    initDocumentEvents() {
        if (this.options.debug) console.log('initDocumentEvents');
        $(document).on('dragenter', () => {
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
            e.preventDefault();
            if (!this.dragging) return;
            this.dragging = false;
            hideElement(this.dropZone);
            showElement(this.el);
        });
        $(document).on('dragover', (e) => {
            if (!this.dragging) return;
            e.preventDefault();
        });
    }

    /**
     * Initializes the elements for the drag and drop functionality.
     */
    initElements() {
        if (this.options.debug) console.log('initElements');
        this.el.data('draggable', 'true');
        this.dropZone = $('<div class="drop-zone">Drop files here</div>');
        const error = $('<div class="upload__error">Error</div>');
        hideElement(error);
        const parent = this.el.parent();
        parent.append(this.dropZone);
        parent.append(error);
        hideElement(this.dropZone);
    }
}

export default FileDrag;
