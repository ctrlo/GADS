import { Component } from 'component'
import '@lol768/jquery-querybuilder-no-eval/dist/js/query-builder.standalone.min'
import { hideElement } from 'util/common'
import TypeaheadBuilder from 'util/typeahead'

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

    this.el.on('afterCreateRuleFilters.queryBuilder', (e, rule) => {
      const select = rule.$el.find('select');
      const options = select.children('option').toArray().filter((option) => { return option.text !== '------' }).map((option) => { return { name: option.text, id: option.value } });
      hideElement(select);
      const search = document.createElement('input');
      search.className = 'form-control';
      search.placeholder = 'Field name...';
      rule.$el.find('.rule-filter-container').append(search);
      const builder = new TypeaheadBuilder();
      builder.withStaticSource(options)
        .withInput($(search))
        .withCallback((value) => {
          this.selectValue(select, value.id);
          $(search).val(value.name);
        })
        .withName('display_conditions')
        .build();
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
