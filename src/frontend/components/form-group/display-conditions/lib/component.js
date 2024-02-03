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

    this.el.on("afterUpdateRuleFilter.queryBuilder", (e, rule) => {
      const select= $(rule.$el.find(`select[name=${rule.id}_filter]`));
      if(!select || !select[0]) console.log("No select found");
      select.data("live-search","true");
      select.selectpicker();
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
