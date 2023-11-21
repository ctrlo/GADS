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
    expect($(div).find('[type="text"]').length).toBe(1);
    expect($(div).find("select").length).toBe(1);
  });

  it("should have list of options in data", () => {
    const div = getDiv();
    const conditions = new DisplayConditionsComponent(div);
    expect(conditions.data.length).toBe(4);
  });

  it("should have all values from the select options in it's data", () => {
    const div = getDiv();
    const component = new DisplayConditionsComponent(div);
    const select = $(div).find("select");
    const options = $(select).find("option");
    const items = component.data;
    expect(options.length).toBe(items.length + 1);
  });
});