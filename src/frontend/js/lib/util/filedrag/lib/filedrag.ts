import { hideElement, showElement } from "util/common";

export interface FileDragOptions {
    allowMultiple?: boolean;
    debug?: boolean;
}

class FileDrag<T extends HTMLElement = HTMLElement> {
    private el: JQuery<T>;
    private dropZone: JQuery<HTMLElement>;
    // for testing
    protected dragging: boolean = false;

    constructor(element: T, private options: FileDragOptions = {}, private onDrop?: (files: FileList | File) => void) {
        this.el = $(element);
        this.initElements()
        this.initDocumentEvents();
        this.initElementEvents();
    }

    initElementEvents() {
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
            showElement(this.el);
            if (this.options.allowMultiple) {
                this.onDrop(e.originalEvent.dataTransfer.files);
            } else {
                this.onDrop(e.originalEvent.dataTransfer.files[0]);
            }
            $(document).trigger('drop');
        });
    }

    initDocumentEvents() {
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
        })
        $(document).on('dragover', (e) => {
            if (!this.dragging) return;
            e.preventDefault();
        });
    }

    initElements() {
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
