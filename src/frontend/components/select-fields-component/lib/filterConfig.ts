import { Field } from './field';

export class FilterConfig {
    searchTerm?: string = undefined;
    fields: Field[] = [];
    get filteredFields(): Field[] { return this.searchTerm ? this.availableFields.filter(f => f.label.includes(this.searchTerm)) : this.availableFields; }
    get selectedFields(): Field[] { return this.fields.filter(f => f.checked); }
    get availableFields(): Field[] { return this.fields.filter(f => !f.checked); }
}
