import { Component } from "component";
import queryBuilder from "@lol768/jquery-querybuilder-no-eval/dist/js/query-builder.standalone.min";

class DisplayConditionsComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initDisplayConditions();
  }

  initDisplayConditions() {
    this.buildConditions(this.el);
  }

  setupSelects(el) {
    const selects = el.find("select");
    const self = this;
    selects.hide();
    selects.each(function () {
      const div = document.createElement("div");
      div.className = "input-container";
      const element = document.createElement("input");
      element.type = "text";
      element.className = "form-control";
      $(element).on("keyup", (ev) => self.textChange(ev));
      div.prepend(element);
      const itemsDiv = document.createElement("div");
      itemsDiv.className = "items";
      $(this)
        .find("option")
        .each(function () {
          if (this.text === "------") return;
          const item = document.createElement("div");
          item.className = "item";
          item.dataset.value = this.value;
          item.innerHTML = this.text;
          $(item).on("click", (ev) => self.itemClick(ev));
          itemsDiv.append(item);
        });
      div.append(itemsDiv);
      this.closest(".rule-filter-container").append(div);
    });
  }

  itemClick(ev) {
    const $container = $(ev.target).closest(".rule-filter-container");
    const $input = $container.find("[type='text']");
    $input.val(ev.target.innerHTML);
    const $select = $container.find("select");
    $select.val(ev.target.dataset.value);
    $select.trigger("change");
  }

  textChange(ev) {
    const $container = $(ev.target).closest(".rule-filter-container");
    const $select = $container.find("select");
    const $items = $container.find(".items");
    const self = this;
    $items.children().remove();
    $select.find("option").each(function () {
      if (this.text === "------") return;
      if (this.text === "") {
        const item = document.createElement("div");
        item.className = "item";
        item.dataset.value = this.value;
        item.innerHTML = this.text;
        $(item).on("click", (ev) => self.itemClick(ev));
        $items.append(item);
      } else if (
        this.text.toLowerCase().includes(ev.target.value.toLowerCase())
      ) {
        const item = document.createElement("div");
        item.className = "item";
        item.dataset.value = this.value;
        item.innerHTML = this.text;
        $(item).on("click", (ev) => self.itemClick(ev));
        $items.append(item);
      }
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

    const builder = el.queryBuilder({
      filters,
      allow_groups: 0,
      operators: [
        { type: "equal", accept_values: true, apply_to: ["string"] },
        { type: "contains", accept_values: true, apply_to: ["string"] },
        { type: "not_equal", accept_values: true, apply_to: ["string"] },
        { type: "not_contains", accept_values: true, apply_to: ["string"] },
      ],
    });

    if (builderData.filterBase) {
      const data = Buffer.from(builderData.filterBase, "base64");
      el.queryBuilder("setRules", JSON.parse(data));
    }
  }
}

export default DisplayConditionsComponent;
