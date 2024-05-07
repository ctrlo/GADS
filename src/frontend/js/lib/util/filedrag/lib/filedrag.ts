import { ElementOrJQueryElement, addClass, hideElement, removeClass, showElement, stopPropagation } from "util/common";

interface FileDragOptions {
    allowMultiple?: boolean;
    debug?: boolean;
}

class FileDrag {
    private el: JQuery<HTMLElement>;
    private dropZone: JQuery<HTMLElement>;
    // for testing
    protected dragging: boolean = false;

    constructor(private element: ElementOrJQueryElement, private options: FileDragOptions = {}, private onDrop?: (files: FileList | File) => void) {
        if (options.debug) console.log('FileDrag', element, options);
        this.el = element instanceof HTMLElement ? $(element) : element;
        this.initElements()
        this.initDocumentEvents();
        this.initElementEvents();
    }

    initElementEvents() {
        if (this.options.debug) console.log('initElementEvents');
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
            if (this.options.debug) console.log(e.originalEvent.dataTransfer.files);
            showElement(this.el);
            console.log(e.originalEvent.dataTransfer.files);
            if (this.options.allowMultiple) {
                this.onDrop(e.originalEvent.dataTransfer.files);
            } else {
                this.onDrop(e.originalEvent.dataTransfer.files[0]);
            }
            $(document).trigger('drop');
            stopPropagation(e);
        });
    }

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

    initElements() {
        if (this.options.debug) console.log('initElements');
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
