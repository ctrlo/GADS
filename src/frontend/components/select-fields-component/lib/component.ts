import { Component } from 'component';
import { Field } from './field';
import { FilterConfig } from './filterConfig';
import { isEmpty } from './util';

export default class SelectFieldsComponent extends Component {
    private $el: JQuery<HTMLElement>;
    private $selectedFields: JQuery<HTMLElement>;
    private $availableFields: JQuery<HTMLElement>;
    private $checkboxes: JQuery<HTMLInputElement>;
    private $searchBox: JQuery<HTMLInputElement>;
    private fieldSetup: FilterConfig;

    constructor(element: HTMLElement) {
        super(element);
        this.$el = $(element);
        this.$selectedFields = this.$el.find("#selectedFields");
        if(!this.$selectedFields.length) {
            throw new Error("Selected fields container not found");
        }
        this.$availableFields = this.$el.find("#availableFields");
        if(!this.$availableFields.length) {
            throw new Error("Available fields container not found");
        }
        this.$checkboxes = this.$el.find<HTMLInputElement>("input[type=\"checkbox\"]");
        if(!this.$checkboxes.length) {
            throw new Error("Checkboxes not found");
        }
        this.$searchBox = this.$el.find<HTMLInputElement>("input[type=\"search\"]");
        if(!this.$searchBox.length) {
            throw new Error("Search box not found");
        }
        this.fieldSetup = new FilterConfig();
        this.init();
    }

    private init() {
        this.$checkboxes.each((_i, box) => {
            this.fieldSetup.fields.push(Field.createField(box));
        });
        console.log("Fields", this.fieldSetup.availableFields, this.fieldSetup.selectedFields, this.fieldSetup.filteredFields, this.fieldSetup.searchTerm);
        this.$checkboxes.on('change', ev => {
            const target = ev.target;
            const value = parseInt(target.getAttribute('value'));
            const checked = target.checked;
            this.fieldSetup.fields.find(f => f.id === value).checked = checked;
            this.refresh();
        });
        this.$searchBox.on('keyup', ev => {
            this.fieldSetup.searchTerm = isEmpty(ev.target.value) ? undefined : ev.target.value;
            console.log("Search term:", this.fieldSetup.searchTerm);
            this.refresh();
        }).on('clear', () => {
            this.fieldSetup.searchTerm = undefined
            this.refresh();
        });
        this.refresh();
    }

    private refresh() {
        this.$availableFields.children('div').remove();
        this.$selectedFields.children('div').remove();
        for (const item of this.fieldSetup.fields) {
            if (item.checked) {
                this.addEntryTo(item, this.$selectedFields);
            } else if(this.fieldSetup.searchTerm === undefined || item.label.includes(this.fieldSetup.searchTerm)) {
                this.addEntryTo(item, this.$availableFields);
            }
        }
    }

    private addEntryTo(entry: Field, target: JQuery<HTMLElement>) {
        const container = document.createElement('div');
        container.classList.add('select-item', 'border-bottom', 'px-1', 'py-2');
        if(target.is(this.$selectedFields)) container.classList.add('selected');
        $(container).on('click', () => $(`#input_${entry.id}`).trigger('click'));
        const item = document.createElement('span');
        item.innerText = entry.label;
        container.append(item);
        target.append(container);
    }
}
