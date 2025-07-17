import { Component } from 'component';

class CollapsibleComponent extends Component {
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.button = this.el.find('.btn-collapsible');
        this.titleCollapsed = this.el.find('.btn__title--collapsed');
        this.titleExpanded = this.el.find('.btn__title--expanded');

        this.initCollapsible(this.button);
    }

    initCollapsible(button) {
        if (!button) {
            return;
        }

        this.titleExpanded.addClass('hidden');
        button.click(() => { this.handleClick(); });
    }

    handleClick() {
        this.titleExpanded.toggleClass('hidden');
        this.titleCollapsed.toggleClass('hidden');
    }
}

export default CollapsibleComponent;
