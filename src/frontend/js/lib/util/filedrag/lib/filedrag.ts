import { HtmlOrJQuery, addClass, hideElement, removeClass, showElement, stopPropagation } from "util/common";

interface FileDragOptions {
    allowMultiple?: boolean;
    debug?: boolean;
}

class FileDrag {
    private el: JQuery<HTMLElement>;
    private dropZone: JQuery<HTMLElement>;
    // for testing
    protected dragging: boolean = false;

    constructor(private element: HtmlOrJQuery, private options: FileDragOptions = {}, private onDrop?: (files: FileList | File) => void) {
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
            hideElement(this.dropZone);
            showElement(this.el);
            console.log(e.originalEvent.dataTransfer.files);
            if (this.options.allowMultiple) {
                this.onDrop(e.originalEvent.dataTransfer.files);
            } else {
                this.onDrop(e.originalEvent.dataTransfer.files[0]);
            }
            stopPropagation(e);
        });
    }

    initDocumentEvents() {
        if (this.options.debug) console.log('initDocumentEvents');
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
        $(document).on('dragover', (e) => {
            if (!this.dragging) return;
            stopPropagation(e);
        });
    }

    initElements() {
        if (this.options.debug) console.log('initElements');
        this.dropZone = $('<div class="drop-zone">Drop files here</div>');
        this.el.parent().append(this.dropZone);
        hideElement(this.dropZone);
    }
}

export default FileDrag;