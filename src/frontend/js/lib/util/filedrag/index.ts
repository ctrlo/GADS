import FileDrag from "./lib/filedrag";

import { FileDragOptions } from "./lib/filedrag";

// The filedrag component is a jQuery plugin that allows for drag and drop file uploads

/**
 * FileDropEvent interface for the filedrag plugin
 * This event is triggered when files are dropped onto the drag area.
 * @prop file - The file that was dropped.
 * @prop index - The index of the file in the list of dropped files.
 * @prop length - The total number of files dropped.
 */
export interface FileDropEvent extends JQuery.TriggeredEvent {
    file: File;
    index: number;
    length: number;
}

export { FileDragOptions }

declare global {
    interface JQuery<TElement = HTMLElement> {
        /**
         * Initialize the filedrag plugin with options
         * @param options - Options for the filedrag plugin
         */
        filedrag(options: FileDragOptions): JQuery<TElement>;
        /**
         * Trigger the fileDrop event
         * @param event - The fileDrop event to trigger
         */
        on(event: "fileDrop", handler: (event: FileDropEvent) => void): JQuery<TElement>;
        /**
         * Trigger the uploadsComplete event
         * @param handler - The handler for the uploadsComplete event
         */
        on(event: "uploadsComplete", handler: (event: JQuery.TriggeredEvent) => void): JQuery<TElement>;
    }
}

export { }

if (typeof jQuery !== "undefined") {
    (function ($) {
        $.fn.filedrag = function (options) {
            options = $.extend({
                allowMultiple: true,
                debug: false
            }, options);

            if (!this.data("filedrag")) {
                this.data("filedrag", "true");
                new FileDrag(this, options, (file, index, length) => {
                    if(index === undefined) index = 1;
                    if(length === undefined) length = 1;
                    if (options.debug) console.log("fileDrop", file, index, length);
                    const event = $.Event("fileDrop", { file, index, length });
                    this.trigger(event);
                })
            }

            return this;
        };
    })(jQuery);
}