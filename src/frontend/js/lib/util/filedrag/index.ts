import FileDrag from "./lib/filedrag";

import { FileDragOptions } from "./lib/filedrag";

declare global {
    interface JQuery<TElement = HTMLElement> {
        filedrag(options: FileDragOptions): JQuery<TElement>;
        on(event: "fileDrop", handler: (event: JQuery.TriggeredEvent, file: File) => void): JQuery<TElement>;
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
                new FileDrag(this, options, (files) => {
                    if (options.debug) console.log("fileDrop", files);
                    this.trigger("fileDrop", files)
                }, ()=>{
                    if (options.debug) console.log("uploadsComplete");
                    this.trigger("uploadsComplete");
                })
            }

            return this;
        };
    })(jQuery);
}