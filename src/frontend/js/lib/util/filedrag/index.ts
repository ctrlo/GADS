import FileDrag from './lib/filedrag';

import { FileDragOptions } from './lib/filedrag';

export interface FileDropEvent extends JQuery.TriggeredEvent {
    file: File;
    index: number;
    length: number;
}

export { FileDragOptions };

declare global {
    interface JQuery<TElement = HTMLElement> {
        filedrag(options: FileDragOptions): JQuery<TElement>;
        on(event: 'fileDrop', handler: (event: FileDropEvent) => void): JQuery<TElement>;
        on(event: 'uploadsComplete', handler: (event: JQuery.TriggeredEvent) => void): JQuery<TElement>;
    }
}

export { };

if (typeof jQuery !== 'undefined') {
    (function ($) {
        $.fn.filedrag = function (options) {
            options = $.extend({
                allowMultiple: true,
                debug: false
            }, options);

            if (!this.data('filedrag')) {
                this.data('filedrag', 'true');
                new FileDrag(this, options, (file, index, length) => {
                    if(index === undefined) index = 1;
                    if(length === undefined) length = 1;
                    if (options.debug) console.log('fileDrop', file, index, length);
                    const event = $.Event('fileDrop', { file, index, length });
                    this.trigger(event);
                });
            }

            return this;
        };
    })(jQuery);
}