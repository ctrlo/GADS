import FileDrag from "./lib/filedrag";

import { FileDragOptions } from "./lib/filedrag";

export interface FileDropEvent extends JQuery.TriggeredEvent {
    file: File;
}

export { FileDragOptions }

declare global {
    interface JQuery<TElement = HTMLElement> {
        filedrag(options: FileDragOptions): JQuery<TElement>;
        on(event: "fileDrop", handler: (event: FileDropEvent) => void): JQuery<TElement>;
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
                new FileDrag(this, options, (file) => {
                    if (options.debug) console.log("fileDrop", file);
                    const event = $.Event("fileDrop", { file });
                    this.trigger(event);
                },
                () => {
                    if (options.debug) console.log("uploadsComplete");
                    const event = $.Event("uploadsComplete");
                    this.trigger(event);
                })
            }

            return this;
        };
    })(jQuery);
}