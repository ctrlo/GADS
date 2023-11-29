import { Component } from 'component'
import '@lol768/jquery-querybuilder-no-eval/dist/js/query-builder.standalone.min'
import { logging } from 'logging'
import TypeaheadBuilder from 'util/typeahead'
import { map } from 'util/typeahead/lib/mapper'

class FilterComponent extends Component {
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.operators = [
      {
        type: 'equal',
        accept_values: true,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'not_equal',
        accept_values: true,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'less',
        accept_values: true,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'less_or_equal',
        accept_values: true,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'greater',
        accept_values: true,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'greater_or_equal',
        accept_values: true,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'contains',
        accept_values: true,
        apply_to: ['datetime', 'string']
      },
      {
        type: 'not_contains',
        accept_values: true,
        apply_to: ['datetime', 'string']
      },
      { type: 'begins_with', accept_values: true, apply_to: ['string'] },
      { type: 'not_begins_with', accept_values: true, apply_to: ['string'] },
      {
        type: 'is_empty',
        accept_values: false,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'is_not_empty',
        accept_values: false,
        apply_to: ['string', 'number', 'datetime']
      },
      {
        type: 'changed_after',
        nb_inputs: 1,
        accept_values: true,
        multiple: false,
        apply_to: ['string', 'number', 'datetime']
      }
    ]
    this.ragProperties = {
      input: 'select',
      values: {
        b_red: 'Red',
        c_amber: 'Amber',
        c_yellow: 'Yellow',
        d_green: 'Green',
        a_grey: 'Grey',
        e_purple: 'Purple'
      }
    }

    this.initFilter()
  }

  initFilter() {
    const self = this
    const $builderEl = this.el
    const builderID = $(this.el).data('builder-id')
    const $builderJSON = $(`#builder_json_${builderID}`)

    if (!$builderJSON.length) return

    const builderConfig = JSON.parse($builderJSON.html())
    const filterBase = $builderEl.data('filter-base')

    if (!builderConfig.filters.length) return
    if (builderConfig.filterNotDone) this.makeUpdateFilter()

    $builderEl.queryBuilder({
      showPreviousValues: builderConfig.showPreviousValues,
      filters: builderConfig.filters.map(col =>
        this.buildFilter(builderConfig, col)
      ),
      allow_empty: true,
      operators: this.operators,
      lang: {
        operators: {
          changed_after: 'changed on or after'
        }
      }
    })

    $builderEl.on('validationError.queryBuilder', function (e, node, error, value) {
      logging.log(error);
      logging.log(value);
      logging.log(e);
      logging.log(node);
    });

    $builderEl.on('afterCreateRuleInput.queryBuilder', function (e, rule) {
      let filterConfig

      builderConfig.filters.forEach(function (value) {
        if (value.filterId === rule.filter.id) {
          filterConfig = value
          return false
        }
      })

      if (!filterConfig || filterConfig.type === 'rag' || !filterConfig.hasFilterTypeahead) {
        return
      }

      const $ruleInputText = $(
        `#${rule.id} .rule-value-container input[type='text']`
      )

      const $ruleInputHidden = $(
        `#${rule.id} .rule-value-container input[type='hidden']`
      )

      $ruleInputText.attr('autocomplete', 'off')

      $ruleInputText.on('keyup', () => {
        $ruleInputHidden.val($ruleInputText.val())
      })

      const filterCallback = (suggestion) => {
        if (filterConfig.useIdInFilter) {
          $ruleInputHidden.val(suggestion.id)
        }
        else {
          $ruleInputHidden.val(suggestion.label)
        }
        $ruleInputHidden.trigger('change')
      }

      const query = $ruleInputText.val()

      const builder = new TypeaheadBuilder()
      builder
        .withInput($ruleInputText)
        .withAjaxSource(self.getURL(builderConfig.layoutId, filterConfig.urlSuffix))
        .withData({ q: query, oi: filterConfig.instanceId })
        .withMapper(m => map(m))
        .withName('rule')
        .withCallback(filterCallback)
        .build();
    })

    if (filterBase) {
      const data = Buffer.from(filterBase, 'base64')
      try {
        const obj = JSON.parse(data);
        if (obj.rules && obj.rules.length) {
          $builderEl.queryBuilder('setRules', obj)
        } else {
          // Ensure that no blank rules by default, otherwise view cannot be submitted
          $builderEl.queryBuilder('setRules', { rules: [] })
        }
      } catch (error) {
        logging.log('Incorrect data object passed to queryBuilder')
      }
    }
  }

  getURL(layoutId, urlSuffix) {
    const devEndpoint = window.siteConfig && window.siteConfig.urls.filterApi

    if (devEndpoint) {
      return devEndpoint
    } else {
      return `/${layoutId}/match/layout/${urlSuffix}`
    }
  }

  makeUpdateFilter(builder) {
    window.UpdateFilter = (builder, ev) => {
      if (!builder.queryBuilder('validate')) ev.preventDefault();
      const res = builder.queryBuilder('getRules')
      $('#filter').val(JSON.stringify(res, null, 2))
    }
  }

  buildFilter = (builderConfig, col) => {
    return ({
      id: col.filterId,
      label: col.label,
      type: 'string',
      operators: this.buildFilterOperators(col.type),
      ...(col.type === 'rag'
        ? this.ragProperties
        : col.hasFilterTypeahead
          ? this.typeaheadProperties(
            col.urlSuffix,
            builderConfig.layoutId,
            col.instanceId,
            col.useIdInFilter
          )
          : {})
    })
  }

  buildFilterOperators(type) {
    if (!['date', 'daterange'].includes(type)) return undefined
    const operators = [
      'equal',
      'not_equal',
      'less',
      'less_or_equal',
      'greater',
      'greater_or_equal',
      'is_empty',
      'is_not_empty'
    ]
    type === 'daterange' && operators.push('contain')
    return operators
  }

  typeaheadProperties = (urlSuffix, layoutId, instanceId, useIdInFilter) => ({
    input: (container, input_name) => {
      return (
        `<div class='typeahead__container'>
          <input class='form-control typeahead_text' type='text' name='${input_name}_text'/>
          <input class='form-control typeahead_hidden' type='hidden' name='${input_name}'/>
        </div>`
      )
    },
    valueSetter: (rule, value) => {
      rule.$el.find('.typeahead_hidden').val(value)
      rule.$el.find('.typeahead_text').val(rule.data.text)
    },
    validation: {
      callback: () => { return true }
    }
  })

  getRecords = (layoutId, urlSuffix, instanceId, query) => {
    return (
      $.ajax({
        type: 'GET',
        url: this.getURL(layoutId, urlSuffix),
        data: { q: query, oi: instanceId },
        dataType: 'json',
        path: 'records'
      })
    )
  }
}

export default FilterComponent
