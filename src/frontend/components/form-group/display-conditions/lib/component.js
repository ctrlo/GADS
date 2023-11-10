import { Component } from 'component';
import '@lol768/jquery-querybuilder-no-eval/dist/js/query-builder.standalone.min';
import 'jquery-typeahead';

class DisplayConditionsComponent extends Component {
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.data = [];
    this.initDisplayConditions()
  }

  initDisplayConditions() {
    this.buildConditions(this.el);
  }

  createTypeaheadDivStructure() {
    const div = document.createElement("div");
    div.className = "typeahead__container";
    const field = document.createElement("div");
    field.className = "typeahead__field";
    const query = document.createElement("div");
    query.className = "typeahead__query";
    const input = document.createElement("input");
    input.type = "text";
    input.className = "js-typeahead";
    input.autocomplete = "on";
    input.name = "js-typeahead";
    query.append(input);
    field.append(query);
    div.append(field);
    this.setupTypeahead(input);
    return div;
  }

  setupSelects(el) {
    const selects = el.find("select");
    const select = $(selects[selects.length - 1]);
    const self = this;
    select.hide();
    select
      .find("option")
      .each(function () {
        if (this.text === "------") return;
        self.addData(this.text, this.value);
      });
    const div = this.createTypeaheadDivStructure();
    select.closest(".rule-filter-container").append(div);
  }

  setupTypeahead(input) {
    const items = this.getItems();
    typeof $.typeahead === "function" && $.typeahead({
      input: input,
      minLength: 1,
      maxItem: 15,
      autocomplete: true,
      order: "asc",
      source: {
        data: items,
      },
      callback: {
        onClickAfter: (node, a, item, event) => {
          event.preventDefault();
          const select = $(node).closest(".rule-filter-container").find("select");
          select.val(this.getValue(item.display));
          select.trigger("change");
        },
      },
    });
  }

  buildConditions(el) {
    const self = this;

    el.on("afterCreateRuleFilters.queryBuilder", (event, filters) => {
      self.setupSelects($(event.target));
    });

    const builderData = el.data();
    const filters = JSON.parse(Buffer.from(builderData.filters, "base64"));
    if (!filters.length) return;

    this.el.queryBuilder({
      filters: filters,
      allow_groups: 0,
      operators: [
        { type: 'equal', accept_values: true, apply_to: ['string'] },
        { type: 'contains', accept_values: true, apply_to: ['string'] },
        { type: 'not_equal', accept_values: true, apply_to: ['string'] },
        { type: 'not_contains', accept_values: true, apply_to: ['string'] }
      ]
    })

    if (builderData.filterBase) {
      const data = Buffer.from(builderData.filterBase, 'base64')
      this.el.queryBuilder('setRules', JSON.parse(data))
    }
  }

  addData(text, value) {
    if (this.checkData(text)) return;
    this.data.push({ text, value });
  }

  checkData(text) {
    return this.data.find((item) => item.text === text);
  }

  getItems() {
    return this.data.map((item) => {
      return item.text;
    });
  }

  getValue(item) {
    return this.data.filter((data) => data.text === item)[0].value;
  }
}

export default DisplayConditionsComponent
