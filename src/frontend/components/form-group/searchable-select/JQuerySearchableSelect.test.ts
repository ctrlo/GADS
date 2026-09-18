/* eslint-disable */
import { describe, it, expect, beforeEach } from "@jest/globals";
import "./JQuerySearchableSelect";

describe("JQuery SearchableSelect component", () => {
    beforeEach(() => {
        document.body.innerHTML = ''; // Clear the document body before each test
    });

    it("Should define the searchableSelect jQuery plugin", () => {
        if(typeof jQuery === 'undefined') expect(true).toBe(false); // fail if jQuery is not loaded
        expect(jQuery.fn.searchableSelect).toBeDefined();
    });

    it("Should initialize searchableSelect on a select element", () => {
        const select = document.createElement('select');
        document.body.appendChild(select);
        $(select).searchableSelect();
        expect($(select).getSearchableSelect).toBeDefined();
        expect($(select).getSearchableSelect()).toBeInstanceOf(Object);
        document.body.removeChild(select);
    });
});
