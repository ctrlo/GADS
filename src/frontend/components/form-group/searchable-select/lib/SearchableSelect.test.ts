/* eslint-disable */
import {describe, it, expect, beforeEach, afterEach} from "@jest/globals";
import {SearchableSelect} from "./SearchableSelect";

describe("SearchableSelect", () => {
    beforeEach(() => {
        document.body.innerHTML = "";
    });

    afterEach(() => {
        document.body.innerHTML = "";
    });

    it("should get the correct last created dropdown ID", () => {
        // Make this a semi-random order to ensure the logic works correctly
        document.body.innerHTML = `
            <div class="dropdown" id="dropdown-3"></div>
            <div class="dropdown" id="dropdown-2"></div>
            <div class="dropdown" id="dropdown-1"></div>
            <div class="dropdown" id="dropdown-4"></div>
        `;
        const lastId = SearchableSelect.getLastCreatedDropdownId();
        expect(lastId).toBe("dropdown-5");
    });

    it("should return dropdown-1 when no dropdowns exist", () => {
        const lastId = SearchableSelect.getLastCreatedDropdownId();
        expect(lastId).toBe("dropdown-1");
    });

    it("should return the correct dropdown ID when no dropdowns match the pattern", () => {
        document.body.innerHTML = `
            <div class="dropdown" id="other-1"></div>
            <div class="dropdown" id="other-2"></div>
        `;
        const lastId = SearchableSelect.getLastCreatedDropdownId();
        expect(lastId).toBe("dropdown-1");
    });

    it("should get the version of Bootstrap", () => {
        const version = SearchableSelect.getBootstrapVersion();
        expect(version).toBeGreaterThan(0);
    });

    it("should be able to create a dropdown", () => {
        const selectElement = document.createElement('select');
        selectElement.innerHTML = `
            <option value="1">Option 1</option>
            <option value="2">Option 2</option>
            <option value="3">Option 3</option>
        `;
        document.body.appendChild(selectElement);

        const searchableSelect = new SearchableSelect(selectElement);
        expect(searchableSelect).toBeInstanceOf(SearchableSelect);
    })
});
