import { Component } from 'component'
import '@lol768/jquery-querybuilder-no-eval/dist/js/query-builder.standalone.min'
import 'bootstrap-select/dist/js/bootstrap-select'

class DisplayConditionsComponent extends Component {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.initDisplayConditions()
  }

  initDisplayConditions() {
    const builderData = this.el.data()
    const filters = JSON.parse(Buffer.from(builderData.filters, 'base64'))
    if (!filters.length) return

    let ruleFilterSelect;
    let operatorSelect;

    this.el.on("afterCreateRuleFilters.queryBuilder", (e, rule) => {
      ruleFilterSelect= $(rule.$el.find(`select[name=${rule.id}_filter]`));
      if(!ruleFilterSelect || !ruleFilterSelect[0]) {
        console.error("No select found");
        return;
      }
      ruleFilterSelect.data("live-search","true");
      ruleFilterSelect.selectpicker();
    });

    this.el.on("afterCreateRuleOperators.queryBuilder", (e, rule, operators) => {
      operatorSelect = $(rule.$el.find(`select[name=${rule.id}_operator]`));
      if(!operatorSelect || !operatorSelect[0]) {
        console.error("No operator select found");
        return;
      }
      if(operatorSelect.data("live-search")) return;
      operatorSelect.data("live-search","true");
      operatorSelect.selectpicker();
    });

    this.el.on("afterSetRules.queryBuilder", (e) => {
      if(!ruleFilterSelect || !ruleFilterSelect[0]) {
        console.error("No select found");
        return;
      }
      ruleFilterSelect.selectpicker("refresh");
      operatorSelect?.selectpicker("refresh");
    });

    this.el.on("afterSetRuleOperator.queryBuilder", (e, rule,operator) => {
      if(!operatorSelect || !operatorSelect[0]) {
        console.error("No select found");
        return;
      }
      operatorSelect.selectpicker("refresh");
    });

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
}

export default DisplayConditionsComponent
