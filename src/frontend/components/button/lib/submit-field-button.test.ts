import {initGlobals} from "testing/globals.definitions";
import SubmitFieldButtonComponent from "./submit-field-button";
import {describe, beforeEach, expect, it} from "@jest/globals";

describe("Submit field button tests", () => {
  beforeEach(() => {
    initGlobals();
  })

  async function loadSubmitFieldButtonComponent(element: HTMLElement) {
    const {default: SubmitFieldButtonComponent} = await import("./submit-field-button");
    return new SubmitFieldButtonComponent($(element));
  }

  it("should create a button", async () => {
    const element = document.createElement("button");
    element.id = "submit-field-button";
    element.classList.add("btn-js-submit-field");
    const button = await loadSubmitFieldButtonComponent(element);
    expect(button).toBeTruthy();
    expect(button).toBeInstanceOf(SubmitFieldButtonComponent);
  });

  it("should perform changes to tree component when one is present", async () => {
    const treeConfig = document.createElement("div")
    treeConfig.id = "tree-config";
    const treeElement = document.createElement("div");
    treeElement.classList.add("tree-widget-container");
    treeConfig.appendChild(treeElement);
    document.body.appendChild(treeConfig);
    const buttonElement = document.createElement("button");
    buttonElement.id = "submit-field-button";
    buttonElement.classList.add("btn-js-submit-field");
    await loadSubmitFieldButtonComponent(buttonElement);
    document.body.appendChild(buttonElement);
    buttonElement.click();
    expect($.ajax).toHaveBeenCalled();
    expect(window.alert).toHaveBeenCalled();
  });
});