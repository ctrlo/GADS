import FileDrag from "./lib/filedrag";

(function ($) {
    $.fn.filedrag = function (options) {
        options = $.extend({
            allowMultiple: true,
            debug: false
        }, options);

        if (!this.data("filedrag")) {
            this.data("filedrag", "true");
            new FileDrag(this, options, (files) => { 
                if(options.debug || window.test) console.log("onFileDrop", files);
                this.trigger("onFileDrop", files) 
            })
        }

        return this;
    };
})(jQuery);