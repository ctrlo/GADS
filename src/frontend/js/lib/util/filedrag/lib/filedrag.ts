import { addClass, hideElement, removeClass, showElement } from "util/common";

/**
 * Options for the FileDrag class
 */
interface FileDragOptions {
    allowMultiple?: boolean;
    debug?: boolean;
}

/**
 * FileDrag class for handling file drag and drop
 */
class FileDrag {
    private el: JQuery<HTMLElement>;
    private dropZone: JQuery<HTMLElement>;
    // for testing
    protected dragging: boolean = false;

    /**
     * Create a new FileDrag instance
     * @param element - The element to attach the file drag to
     * @param options - Options for the file drag
     * @param onDrop - Callback function to be called when a file is dropped
     */
    constructor(element: HTMLElement);
    constructor(element: JQuery<HTMLElement>);
    constructor(element: HTMLElement, options: FileDragOptions);
    constructor(element: JQuery<HTMLElement>, options: FileDragOptions);
    constructor(element: HTMLElement, options: FileDragOptions, onDrop: (files: FileList | File) => void);
    constructor(element: JQuery<HTMLElement>, options: FileDragOptions, onDrop: (files: FileList | File) => void);
    constructor(element: HTMLElement | JQuery<HTMLElement>, private options: FileDragOptions = {}, private onDrop?: (files: FileList | File) => void) {
        if (options.debug) console.log("FileDrag", element, options);
        this.el = element instanceof HTMLElement ? $(element) : element;
        this.initElements();
        this.initDocumentEvents();
        this.initElementEvents();
    }

    /**
     * Initialize the element events
     */
    private initElementEvents() {
        if (this.options.debug) console.log("initElementEvents");
        this.dropZone.on("dragenter", (e) => {
            if (!this.dragging) return;
            addClass(this.dropZone, "dragging");
            e.preventDefault();
        });
        this.dropZone.on("dragleave", (e) => {
            if (!this.dragging) return;
            removeClass(this.dropZone, "dragging");
            e.preventDefault();
        });
        this.dropZone.on("drop", (e) => {
            if (!this.dragging) return;
            this.dragging = false;
            removeClass(this.el, "dragging");
            hideElement($(".drop-zone"));
            showElement($("[data-draggable=\"true\"]"));
            if (this.options.debug) console.log(e.originalEvent.dataTransfer.files);
            showElement(this.el);
            console.log(e.originalEvent.dataTransfer.files);
            if (this.options.allowMultiple) {
                this.onDrop(e.originalEvent.dataTransfer.files);
            } else {
                this.onDrop(e.originalEvent.dataTransfer.files[0]);
            }
            $(document).trigger("drop");
            e.preventDefault();
        });
    }

    /**
     * Initialize the document events
     */
    private initDocumentEvents() {
        if (this.options.debug) console.log("initDocumentEvents");
        $(document).on("dragenter", () => {
            if (this.dragging) return;
            this.dragging = true;
            hideElement(this.el);
            showElement(this.dropZone);
        });
        $(document).on("dragleave", (e) => {
            if (!this.dragging) return;
            if (e.originalEvent.pageX != 0 || e.originalEvent.pageY != 0) {
                return false;
            }
            this.dragging = false;
            hideElement(this.dropZone);
            showElement(this.el);
        });
        $(document).on("drop", (e) => {
            if (!this.dragging) return;
            this.dragging = false;
            hideElement(this.dropZone);
            showElement(this.el);
            e.stopPropagation();
        });
        $(document).on("dragover", (e) => {
            if (!this.dragging) return;
            e.stopPropagation();
        });
    }

    /**
     * Initialize the elements and add them to the DOM
     */
    initElements() {
        if (this.options.debug) console.log("initElements");
        this.el.data("draggable", "true");
        this.dropZone = $("<div class=\"drop-zone\">Drop files here</div>");
        const error = $("<div class=\"upload__error\">Error</div>");
        hideElement(error);
        const parent = this.el.parent();
        parent.append(this.dropZone);
        parent.append(error);
        hideElement(this.dropZone);
    }
}

export default FileDrag;
