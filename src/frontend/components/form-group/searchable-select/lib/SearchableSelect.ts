import { Tooltip } from 'bootstrap';
import { logging } from 'logging';

/**
 * SearchableSelect class provides a searchable dropdown interface for a standard HTML select element.
 */
export class SearchableSelect {
    dropdown: HTMLDivElement = null;
    button: HTMLButtonElement = null;
    target: HTMLElement;

    /**
     * Create a SearchableSelect instance.
     * @param target The target HTMLElement where the dropdown will be appended.
     * @param element The HTMLSelectElement that will be transformed into a searchable dropdown.
     */
    constructor(private element: HTMLSelectElement, target?:HTMLElement) {
        this.target = target || element.parentElement || document.body;
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
        const id = SearchableSelect.getLastCreatedDropdownId();
        this.dropdown = document.createElement('div');
        this.dropdown.className = 'dropdown';
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
            a.addEventListener('click', (e) => {
                e.preventDefault();
                this.element.value = option.value;
                this.refresh();
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
        this.button = document.createElement('button');
        this.button.className = 'btn btn-secondary dropdown-toggle w-100';
        this.button.type = 'button';
        this.button.setAttribute(SearchableSelect.getBootstrapVersion() >= 5 ? 'data-bs-toggle' : 'data-toggle', 'dropdown');
        this.button.setAttribute('aria-expanded', 'false');
        this.button.textContent = 'Select an option';
        dropdown.appendChild(this.button);
    }

    /**
     * Creates a unique ID for the dropdown based on existing dropdowns in the document.
     * @returns A unique ID for the dropdown, incrementing from the last created dropdown ID.
     */
    static getLastCreatedDropdownId(): string {
        const dropdowns = document.querySelectorAll('.dropdown');
        if (dropdowns.length === 0) {
            return 'dropdown-1';
        }
        console.log(dropdowns.length);
        const filteredDropdowns = Array.from(dropdowns).filter((dropdown) => {
            return dropdown.id.startsWith('dropdown-');
        });
        console.log(filteredDropdowns.length);
        if (filteredDropdowns.length === 0) {
            return 'dropdown-1';
        }
        const lastID = filteredDropdowns.map((dropdown) => {
            const match = dropdown.id.match(/dropdown-(\d+)/);
            const r = match ? parseInt(match[1], 10) : 0;
            logging.info(`Found dropdown ID: ${dropdown.id}, parsed ID: ${r}`);
            return r;
        }).reduce((max, id) => Math.max(max, id), 0);
        logging.info(`Last dropdown ID found: ${lastID}`);
        return `dropdown-${lastID+1}`;
    }

    /**
     * Gets the major version of Bootstrap being used.
     * @returns The major version of Bootstrap being used, based on the Tooltip.VERSION.
     */
    static getBootstrapVersion(): number {
        return parseInt(Tooltip.VERSION.split('.')[0]);
    }

    /**
     * Refreshes the dropdown button text and triggers a change event on the original select element.
     */
    refresh() {
        this.button.textContent = this.element.options[this.element.selectedIndex]?.text || 'Select an option';
        this.element.dispatchEvent(new Event('change'));
    }
}
