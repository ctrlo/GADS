import { describe, it, expect, afterEach } from '@jest/globals';
import ToggleListBox from './component.ts';

describe('ToggleListBox', () => {
    const baseOptions = { withBody: false, withCheckboxes: false, items: [] };

    const createBaseDom = (options: { withBody: boolean, withCheckboxes: boolean, items: { label: string, id: string, checked?: boolean }[] }) => {
        const { withBody, withCheckboxes, items } = { ...baseOptions, ...options };
        const div = document.createElement('div');
        const available = createListbox('rows-available', withBody);
        const selected = createListbox('rows-selected', withBody);
        div.appendChild(available);
        div.appendChild(selected);
        if (withCheckboxes) {
            if (!items.length) {
                const div2 = createCheckbox('test', 'test');
                div.appendChild(div2);
            }
            else {
                items.forEach((item) => {
                    const div2 = createCheckbox(item.label, item.id, item.checked ?? false);
                    div.appendChild(div2);
                });
            }
        }
        return div;
    };

    const createListbox = (id: string, withBody: boolean) => {
        const div = document.createElement('div');
        div.id = id;
        if (withBody) {
            const body = document.createElement('div');
            body.classList.add('listbox-content');
            div.appendChild(body);
        }
        return div;
    };

    const createCheckbox = (label: string, id: string, checked:boolean = false) => {
        const div = document.createElement('div');
        const input = document.createElement('input');
        input.type = 'checkbox';
        input.id = id;
        if (checked) {
            input.setAttribute('checked', 'checked');
        }
        const labelElement = document.createElement('label');
        labelElement.textContent = label;
        div.appendChild(input);
        div.appendChild(labelElement);
        return div;
    };

    afterEach(() => {
        document.body.innerHTML = '';
    });

    it('Errors if there is no listbox-content element', () => {
        const div = createBaseDom({ withBody: false, withCheckboxes: true, items: [] });
        document.body.appendChild(div);
        expect(() => new ToggleListBox(div)).toThrowError('No element provided');
    });

    it('Creates a listbox with the correct content when checkboxes are unchecked', ()=>{
        const div = createBaseDom({ withBody: true, withCheckboxes: true, items: [{ label: 'test', id: 'test' }] });
        document.body.appendChild(div);
        const toggleListBox = new ToggleListBox(div);
        const availableList = document.getElementById('rows-available');
        const selectedList = document.getElementById('rows-selected');
        const items = availableList?.querySelector('div.listbox-content')?.childElementCount;
        const selectedItems = selectedList?.querySelector('div.listbox-content')?.childElementCount;
        expect(items).toBe(1);
        expect(selectedItems).toBe(0);
    });

    it('Creates a listbox with the correct content when checkboxes are checked', ()=>{
        const div=createBaseDom({ withBody: true, withCheckboxes: true, items: [{ label: 'test', id: 'test', checked: true }] });
        document.body.appendChild(div);
        const toggleListBox = new ToggleListBox(div);
        const availableList = document.getElementById('rows-available');
        const availableItems = availableList?.querySelector('div.listbox-content')?.childElementCount;
        const selectedList = document.getElementById('rows-selected');
        const items = selectedList?.querySelector('div.listbox-content')?.childElementCount;
        expect(items).toBe(1);
        expect(availableItems).toBe(0);
    });

    it('Creates a listbox with the correct content when some checkboxes are checked', ()=>{
        const div = createBaseDom({ withBody: true, withCheckboxes: true, items: [{ label: 'test', id: 'test', checked: true }, { label: 'test2', id: 'test2' }] });
        document.body.appendChild(div);
        const toggleListBox = new ToggleListBox(div);
        const availableList = document.getElementById('rows-available');
        const availableItems = availableList?.querySelector('div.listbox-content')?.childElementCount;
        const selectedList = document.getElementById('rows-selected');
        const items = selectedList?.querySelector('div.listbox-content')?.childElementCount;
        expect(items).toBe(1);
        expect(availableItems).toBe(1);
    });
});