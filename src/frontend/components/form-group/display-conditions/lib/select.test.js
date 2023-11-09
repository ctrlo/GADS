import DisplayConditionsComponent from "./component";

global.$ = require("jquery");

describe("tests for component replacement", () => {
  const getDiv = () => {
    const div = document.createElement("div");
    div.classList.add("rule-filter-container");
    div.id = "displayConditionsBuilder";
    $(div).data(
      "filters",
      "W3siaWQiOiI4IiwidHlwZSI6InN0cmluZyIsImxhYmVsIjoiVGVzdCJ9LHsidHlwZSI6InN0cmluZyIsImxhYmVsIjoiVGVzdCBPdGhlciBWYWx1ZSIsImlkIjoiMTEifSx7ImlkIjoiMTIiLCJ0eXBlIjoic3RyaW5nIiwibGFiZWwiOiJUZXN0IFJBRyJ9LHsiaWQiOiIxMyIsInR5cGUiOiJzdHJpbmciLCJsYWJlbCI6IlBlcnNvbiBUZXN0In1d"
    );
    return div;
  };

  it("should replace selects with inputs", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    expect($(div).find('input[type="text"]').length).toBe(1);
    expect($(div).find("select").length).toBe(1);
  });

  it("should have list of options below inputs", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    expect($(div).find(".item").length).toBe(4);
  });

  it("should change the select value on click of the item", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    const item = $(div).find(".item")[0];
    expect(item.dataset.value).toBe("8");
    $(item).trigger("click");
    expect($(div).find("select").val()).toBe("8");
  });

  it("should provide a list of options below according to text entered", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    const input = $(div).find('input[type="text"]');
    input.val("Test");
    input.trigger("keyup");
    expect($(div).find(".item").length).toBe(4);
    input.val("er");
    input.trigger("keyup");
    expect($(div).find(".item").length).toBe(2);
  });

  it("should provide a list of all items below if no text is in the textbox", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    const input = $(div).find('input[type="text"]');
    input.val("er");
    input.trigger("keyup");
    expect($(div).find(".item").length).toBe(2);
    input.val("");
    input.trigger("keyup");
    expect($(div).find(".item").length).toBe(4);
  });

  it("should change the textarea value on click", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    const input = $(div).find('input[type="text"]');
    input.val("Test");
    input.trigger("keyup");
    const item = $(div).find(".item")[0];
    const firstOption = $(div).find("option")[1]; //Actual first option is "------" which is ignored!
    $(item).trigger("click");
    expect($(div).find('input[type="text"]').val()).toBe(firstOption.text);
  });

  it("should have all values from the select options used below the textbox", () => {
    const div = getDiv();
    new DisplayConditionsComponent(div);
    const select = $(div).find("select");
    const options = $(select).find("option");
    const items = $(div).find(".item");
    expect(options.length).toBe(items.length + 1);
  });

  it("should hide all items on item select", ()=>{
    const div=getDiv();
    new DisplayConditionsComponent(div);
    const input = $(div).find('input[type="text"]');
    input.val("Test");
    input.trigger("keyup");
    const item = $(div).find(".item")[0];
    $(item).trigger("click");
    expect($(div).find(".item").length).toBe(0);
  });
});