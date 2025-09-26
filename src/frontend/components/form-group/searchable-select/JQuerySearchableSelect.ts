import { SearchableSelect } from './lib/SearchableSelect';
import { SearchableSelectOptions } from './lib/options';

if (typeof jQuery === 'undefined') throw new Error('jQuery is not loaded. Please include jQuery before this script.');

declare global {
    interface JQuery {
        searchableSelect: (options?: SearchableSelectOptions) => JQuery;
        getSearchableSelect: () => SearchableSelect;
    }
}

export { };

(($) => {
    const selectMap = new Map<HTMLSelectElement, SearchableSelect>();
    $.fn.searchableSelect = function (options?: SearchableSelectOptions) {
        if (this.length === 0) return this;
        const settings: SearchableSelectOptions = $.extend({
            target: this.parent()[0],
            classList: [],
            placeholder: 'Select an option',
            element: this[0] as HTMLSelectElement,
        }, options);
        this.each(function () {
            const element = this as HTMLSelectElement;
            if (element.tagName.toLowerCase() === 'select') {
                const select = new SearchableSelect(settings);
                selectMap.set(element, select);
                $(element).data('searchableSelect', 'true');
            } else {
                console.warn('Element is not a select:', element);
            }
        });
        return this;
    };
    $.fn.getSearchableSelect = function () {
        const element = this[0] as HTMLSelectElement;
        if (element && selectMap.get(element)) {
            return selectMap.get(element) as SearchableSelect;
        } else {
            console.warn('No SearchableSelect instance found for this element:', element);
            return null;
        }
    };
})(jQuery);
