import { Component } from 'component'
import 'jQuery-QueryBuilder'
import { logging } from 'logging'
import TypeaheadBuilder from 'util/typeahead'
import { refreshSelects } from 'components/form-group/common/bootstrap-select'

/**
 * Filter Component
 */
class FilterComponent extends Component {
  /**
   * Create a new Filter Component
   * @param {HTMLElement} element The element to initialize the component on
   */
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
        e_purple: 'Purple',
        d_blue: 'Blue',
        b_attention: 'Red (Attention)'
      }
    }

    this.initFilter()
  }

  /**
   * Initialize the filter component
   */
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

    refreshSelects(this.el);

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
        } else {
          $ruleInputHidden.val(suggestion.name)
        }
      }

      // This is required to ensure that the correct query is sent each time
      const buildQuery = () => { return { q: $ruleInputText.val(), oi: filterConfig.instanceId } }

      const builder = new TypeaheadBuilder();
      builder
        .withInput($ruleInputText)
        .withAjaxSource(self.getURL(builderConfig.layoutId, filterConfig.urlSuffix))
        .withDataBuilder(buildQuery)
        .withDefaultMapper()
        .withName('rule')
        .withAppendQuery()
        .withCallback(filterCallback)
        .build()
    })

    if (filterBase) {
      const data = atob(filterBase, 'base64')
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

  /**
   * Get the URL for the API endpoint
   * @param {*} layoutId The layout ID
   * @param {*} urlSuffix The suffix for the URL
   * @returns {string} The URL
   */
  getURL(layoutId, urlSuffix) {
    const devEndpoint = window.siteConfig && window.siteConfig.urls.filterApi

    if (devEndpoint) {
      return devEndpoint
    } else {
      return `/${layoutId}/match/layout/${urlSuffix}?q=`
    }
  }

  /**
   * Make the update filter function
   */
  makeUpdateFilter() {
    window.UpdateFilter = (builder, ev) => {
      if (!builder.queryBuilder('validate')) ev.preventDefault();
      const res = builder.queryBuilder('getRules')
      $('#filter').val(JSON.stringify(res, null, 2))
    }
  }

  /**
   * Build the filter object
   * @param {object} builderConfig The builder configuration
   * @param {*} col The column configuration
   * @returns A filter object
   */
  buildFilter = (builderConfig, col) => {
    return ({
      id: col.filterId,
      label: col.label,
      type: 'string',
      operators: this.buildFilterOperators(col.type),
      ...(col.type === 'rag'
        ? this.ragProperties
        : {})
    })
  }

  /**
   * Build the filter operators
   * @param {*} type The datatype
   * @returns The filter operators
   */
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

  /**
   * Get the records from the API
   * @param {*} layoutId The layout ID
   * @param {*} urlSuffix The URL suffix
   * @param {*} instanceId The instance ID
   * @param {*} query The query
   * @returns An AJAX request
   */
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
