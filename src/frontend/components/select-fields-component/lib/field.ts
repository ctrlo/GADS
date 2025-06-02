import { isDefined, isEmpty } from './util';


export class Field {
    private constructor(public id: number, public label: string, public checked: boolean) {
    }

    static createField(element: HTMLInputElement) {
        const id = element.value;
        if (!isDefined(id) || isEmpty(id)) {
            throw new Error('Field ID is not defined or empty');
        }
        const label = document.querySelector(`label[for="${element.id}"]`)?.textContent;
        if (!isDefined(label) || isEmpty(label)) {
            throw new Error('Field label is not defined or empty');
        }
        const checked = element.checked;
        return new Field(parseInt(id), label, checked);
    }
}
