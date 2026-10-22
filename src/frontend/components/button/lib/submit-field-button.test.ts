import { describe, it, expect, beforeAll } from '@jest/globals';
/* eslint-disable jsdoc/require-jsdoc */
/* eslint-disable @typescript-eslint/ban-ts-comment */
/* @ts-ignore */
import { initGlobals } from 'testing/globals.definitions';
// import SubmitFieldButtonComponent from './submit-field-button';

describe.skip('Submit field button tests - error in Jest means QB doesn\'t load', () => {
    beforeAll(() => {
        initGlobals();
    });

    it("should perform changes to tree component when one is present", () => {
        const treeConfig = document.createElement("div")
        treeConfig.id = "tree-config";
        const treeElement = document.createElement("div");
        treeElement.classList.add("tree-widget-container");
        treeConfig.appendChild(treeElement);
        document.body.appendChild(treeConfig);
        const buttonElement = document.createElement("button");
        buttonElement.id = "submit-field-button";
        buttonElement.classList.add("btn-js-submit-field");
        new SubmitFieldButtonComponent($(buttonElement));
        document.body.appendChild(buttonElement);
        buttonElement.click();
        expect($.ajax).toHaveBeenCalled();
        expect(window.alert).toHaveBeenCalled();
    });
});
