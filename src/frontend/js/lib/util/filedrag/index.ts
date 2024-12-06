import FileDrag from "./lib/filedrag";

import { FileDragOptions } from "./lib/filedrag";

declare global {
    interface JQuery<TElement = HTMLElement> {
        filedrag(options: FileDragOptions): JQuery<TElement>;
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
                    if (options.debug) console.log("onFileDrop", files);
                    this.trigger("onFileDrop", files)
                })
            }

            return this;
        };
    })(jQuery);
}