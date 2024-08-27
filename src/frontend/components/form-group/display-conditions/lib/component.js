import { Component } from 'component'
import '@lol768/jquery-querybuilder-no-eval/dist/js/query-builder.standalone.min'
import 'bootstrap-select/dist/js/bootstrap-select'
import { refreshSelects } from 'components/form-group/common/bootstrap-select'
import { fromJson } from 'util/common'

class DisplayConditionsComponent extends Component {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.initDisplayConditions()
  }

  initDisplayConditions() {
    const builderData = this.el.data()
    const filters = JSON.parse(atob(builderData.filters))
    if (!filters.length) return

    refreshSelects(this.el)

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
      const data = JSON.parse(atob(builderData.filterBase))
      this.el.queryBuilder('setRules', data)
    }
  }
}

export default DisplayConditionsComponent
