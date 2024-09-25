import FileDrag from "./lib/filedrag";

export interface FileDragOptions {
    allowMultiple?: boolean;
    debug?: boolean;
}

declare global {
    interface JQuery<TElement = HTMLElement, T extends HTMLElement = HTMLElement> {
        filedrag(options: {
            allowMultiple: boolean,
            debug: boolean
        }): JQuery<TElement,T>;
    }
}

(function ($) {
    $.fn.filedrag = function (options) {
        options = $.extend({
            allowMultiple: true,
            debug: false
        }, options);

        if (!this.data("filedrag")) {
            this.data("filedrag", "true");
            new FileDrag(this, options, (files) => { 
                if(options.debug) console.log("onFileDrop", files);
                this.trigger("onFileDrop", files) 
            })
        }

        return this;
    };
})(jQuery);