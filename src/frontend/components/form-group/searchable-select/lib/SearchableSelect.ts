import { Tooltip } from 'bootstrap';
import { SearchableSelectOptions } from './options';

/**
 * SearchableSelect class provides a searchable dropdown interface for a standard HTML select element.
 */
export class SearchableSelect {
    dropdown: HTMLDivElement = null;
    button: HTMLElement = null;
    target: HTMLElement;
    element: HTMLSelectElement;
    classList: string[];
    placeholder: string;

    /**
     * Create a SearchableSelect instance.
     * @param target The target HTMLElement where the dropdown will be appended.
     * @param element The HTMLSelectElement that will be transformed into a searchable dropdown.
     */
    constructor({ element, target, classList, placeholder }: SearchableSelectOptions) {
        this.element = element;
        this.target = target || element.parentElement || document.body;
        this.classList = classList || [];
        this.placeholder = placeholder || 'Select an option';
        this.init();
    }

    /**
     * Initializes the SearchableSelect by creating the dropdown and hiding the original select element.
     * It also sets up the event listeners for the search input and option selection.
     * @private
     */
    private init() {
        const options = Array.from(this.element.options);
        this.createDropdown(options);
        this.element.style.display = 'none'; // Hide the original select element
    }

    /**
     * Creates the dropdown element and appends it to the target.
     * This method generates a unique ID for the dropdown and creates the button and options list.
     * @param options An array of HTMLOptionElement objects to populate the dropdown.
     * @private
     */
    private createDropdown(options: HTMLOptionElement[]) {
        const id = SearchableSelect.LastCreatedDropdownId;
        this.dropdown = document.createElement('div');
        this.dropdown.className = 'dropdown btn-searchable-select';
        this.dropdown.id = id;
        this.createButton(this.dropdown);
        this.createOptions(options, this.dropdown);
        this.target.appendChild(this.dropdown);
        this.refresh();
    }

    /**
     * Creates the options list for the dropdown.
     * It includes a search input field at the top for filtering options.
     * @param options An array of HTMLOptionElement objects to populate the dropdown.
     * @param dropdown The HTMLDivElement that represents the dropdown container.
     * @private
     */
    private createOptions(options: HTMLOptionElement[], dropdown: HTMLDivElement) {
        const ul = document.createElement('ul');
        ul.className = 'dropdown-menu';
        const searchLi = document.createElement('li');
        searchLi.classList.add('searchable-select-search', 'dropdown-item');
        const searchInput = document.createElement('input');
        searchInput.type = 'text';
        searchInput.className = 'form-control';
        searchInput.placeholder = 'Search...';
        searchInput.addEventListener('input', () => {
            this.createOptionsList(options, searchInput.value, ul);
        });
        searchLi.appendChild(searchInput);
        ul.appendChild(searchLi);
        this.createOptionsList(options, '', ul);
        dropdown.appendChild(ul);
    }

    /**
     * Creates the list of options based on the current search input.
     * @param options Array of HTMLOptionElement objects to filter and display in the dropdown.
     * @param searchInput The current value of the search input field.
     * @param ul The HTMLUListElement where the filtered options will be appended.
     */
    private createOptionsList(options: HTMLOptionElement[], searchInput: string, ul: HTMLUListElement) {
        ul.querySelectorAll('.searchable-select-option').forEach(option => option.remove());
        options.filter(o => o.text.toLowerCase().includes(searchInput.toLowerCase())).forEach(option => {
            const li = document.createElement('li');
            const a = document.createElement('a');
            a.classList.add('dropdown-item', 'searchable-select-option');
            a.href = '#';
            a.textContent = option.text;
            a.role = 'option';
            a.addEventListener('click', (e) => {
                e.preventDefault();
                this.element.value = option.value;
                this.refresh();
                this.element.dispatchEvent(new Event('change', { bubbles: true }));
            });
            li.appendChild(a);
            ul.appendChild(li);
        });
    }

    /**
     * Creates the button that toggles the dropdown.
     * @param dropdown The HTMLDivElement that represents the dropdown container.
     */
    private createButton(dropdown: HTMLDivElement) {
        const button = document.createElement('button');
        button.classList.add('btn', 'dropdown-toggle', 'btn-searchable-select', ...this.classList);
        button.type = 'button';
        button.setAttribute(SearchableSelect.BootstrapVersion >= 5 ? 'data-bs-toggle' : 'data-toggle', 'dropdown');
        button.setAttribute('aria-expanded', 'false');
        const span = document.createElement('span');
        span.textContent = 'Select an option';
        button.appendChild(span);
        this.button = span;
        dropdown.appendChild(button);
    }

    /**
     * Creates a unique ID for the dropdown based on existing dropdowns in the document.
     * @returns A unique ID for the dropdown, incrementing from the last created dropdown ID.
     */
    static get LastCreatedDropdownId(): string {
        const dropdowns = document.querySelectorAll('.dropdown');
        if (dropdowns.length === 0) {
            return 'dropdown-1';
        }
        const filteredDropdowns = Array.from(dropdowns).filter((dropdown) => {
            return dropdown.id.startsWith('dropdown-');
        });
        if (filteredDropdowns.length === 0) {
            return 'dropdown-1';
        }
        const lastID = filteredDropdowns.map((dropdown) => {
            const match = dropdown.id.match(/dropdown-(\d+)/);
            const r = match ? parseInt(match[1], 10) : 0;
            return r;
        }).reduce((max, id) => Math.max(max, id), 0);
        return `dropdown-${lastID + 1}`;
    }

    /**
     * Gets the major version of Bootstrap being used.
     * @returns The major version of Bootstrap being used, based on the Tooltip.VERSION.
     */
    static get BootstrapVersion(): number {
        return parseInt(Tooltip.VERSION.split('.')[0]);
    }

    /**
     * Refreshes the dropdown button text and triggers a change event on the original select element.
     */
    refresh() {
        this.button.textContent = this.element.options[this.element.selectedIndex]?.text || 'Select an option';
        $(this.dropdown).find('.dropdown-item')
            .each((index, item) => {
                if (item.textContent === this.button.textContent) {
                    item.classList.add('active');
                } else {
                    item.classList.remove('active');
                }
            });
    }
}
