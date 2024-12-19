import { Component } from 'component'
import { DataSet, Timeline } from 'vis-timeline/standalone'
import moment from 'moment'
import TippyComponent from '../tippy/lib/component.js'
import Handlebars from 'handlebars'
import './handlebars/handlebars-timeline-item-template.js'
import './print/timeline'

class TimelineComponent extends Component {
    constructor(element)  {
        super(element)
        this.el = $(this.element)

        this.initTimeline()
        this.tl_request = undefined
    }

    initTimeline() {
      const $container = $(this.element).find('.timeline__visualization')
      const records_base64 = $container.data('records')
      const json = atob(records_base64)
      const dataset = JSON.parse(json)
      this.injectContrastingColor(dataset)

      const items = new DataSet(dataset)
      let groups = $container.data('groups')
      const json_group = atob(groups)
      groups = JSON.parse(json_group)
      const is_dashboard = !!$container.data('dashboard')
      const layout_identifier = $('body').data('layout-identifier')

      // See http://visjs.org/docs/timeline/#Editing_Items
      const options = {
        margin: {
          item: {
            horizontal: -1
          }
        },
        moment: function(date) {
          return moment(date).utc()
        },
        clickToUse: is_dashboard,
        zoomFriction: 10,
        template: Handlebars.templates.timelineitem,
        orientation: { axis: 'both' }
      }

      // Merge any additional options supplied
      // for (const attrname in options_in) {
      //   options[attrname] = options_in[attrname]
      // }

      // options.on_move = on_move
      // options.snap = this.snapToDay()

      if ($container.data('min')) {
        options.start = $container.data('min')
      }

      if ($container.data('max')) {
        options.end = $container.data('max')
      }

      if ($container.data('width')) {
        options.width = $container.data('width')
      }

      if ($container.data('height')) {
        options.width = $container.data('height')
      }

      if (!$container.data('rewind')) {
        options.editable = {
          add: false,
          updateTime: true,
          updateGroup: false,
          remove: false
        }
        options.multiselect = true
      }

      const tl = new Timeline($container.get(0), items, options)
      if (groups.length > 0) {
        tl.setGroups(groups)
      }

      let firstshow=true
      const self = this
      tl.on("changed", function (properties) {
        if (firstshow) {
          self.setupTippy()
          firstshow = false
        }
      })
      
      // functionality to add new items on range change
      let persistent_max
      let persistent_min
      tl.on('rangechanged', function(props) {
        if (!props.byUser) {
          if (!persistent_min) {
            persistent_min = props.start.getTime()
          }
          if (!persistent_max) {
            persistent_max = props.end.getTime()
          }
          return
        }

        // Shortcut - see if we actually need to continue with calculations
        if (
          props.start.getTime() > persistent_min &&
          props.end.getTime() < persistent_max
        ) {
          update_range_session(props)
          return
        }

        $container.prev('.timeline__loader').show()

        /* Calculate the range of the current items. This will min/max
              values for normal dates, but for dateranges we need to work
              out the dates of what was retrieved. E.g. the earliest
              end of a daterange will be the start of the range of
              the current items (otherwise it wouldn't have been
              retrieved)
          */

        // Get date range with earliest start
        let val = items.min('start')

        // Get date range with latest start
        val = items.max('start')
        const max_start = val ? new Date(val.start) : undefined

        // Get date range with earliest end
        val = items.min('end')
        const min_end = val ? new Date(val.end) : undefined

        // If this is a date range without a time, then the range will have
        // automatically been altered to add an extra day to its range, in
        // order to show it across the expected period on the timeline (see
        // Timeline.pm). When working out the range to request, we have to
        // remove this extra day, as searching the database will not include it
        // and we will otherwise end up with duplicates being retrieved
        if (min_end && !val.has_time) {
          min_end.setDate(min_end.getDate() - 1)
        }

        // Get date range with latest end
        val = items.max('end') 

        // Get earliest single date item
        val = items.min('single')
        const min_single = val ? new Date(val.single) : undefined

        // Get latest single date item
        val = items.max('single')
        const max_single = val ? new Date(val.single) : undefined

        // Now work out the actual range we have items for
        const have_range = {}

        if (min_end && min_single) {
          // Date range items and single date items
          have_range.min = min_end < min_single ? min_end : min_single
        } else {
          // Only one or the other
          have_range.min = min_end || min_single
        }

        if (max_start && max_single) {
          // Date range items and single date items
          have_range.max = max_start > max_single ? max_start : max_single
        } else {
          // Only one or the other
          have_range.max = max_start || max_single
        }
        /* haverange now contains the min and max of the current
              range. Now work out whether we need to fill to the left or
              right (or both)
          */
        let from
        let to

        if (!have_range.min) {
          from = props.start.getTime()
          to = props.end.getTime()
          load_items(from, to)
        }

        if (props.start < have_range.min) {
          from = props.start.getTime()
          to = have_range.min.getTime()
          load_items(from, to, 'to')
        }

        if (props.end > have_range.max) {
          from = have_range.max.getTime()
          to = props.end.getTime()
          load_items(from, to, 'from')
        }

        if (!persistent_max || persistent_max < props.end.getTime()) {
          persistent_max = props.end.getTime()
        }

        if (!persistent_min || persistent_min > props.start.getTime()) {
          persistent_min = props.start.getTime()
        }

        $container.prev('.timeline__loader').hide()

        // leave to end in case of problems rendering this range
        update_range_session(props)
      })
      const csrf_token = $('body').data('csrf-token')
      /**
       * @param {object} props
       * @returns {void}
       */
      function update_range_session(props) {
        // Do not remember timeline range if adjusting timeline on dashboard
        if (!is_dashboard) {
          $.post({
            url: '/' + layout_identifier + '/data_timeline?',
            data:
              'from=' +
              props.start.getTime() +
              '&to=' +
              props.end.getTime() +
              '&csrf_token=' +
              csrf_token
          })
        }
      }

      /**
       * @param {string} from
       * @param {string} to
       * @param {string} exclusive
       */
      function load_items(from, to, exclusive) {
        /* we use the exclusive parameter to not include ranges
              that go over that date, otherwise we will retrieve
              items that we already have */
        let url =
          '/' +
          layout_identifier +
          '/data_timeline/' +
          '10' +
          '?from=' +
          from +
          '&to=' +
          to +
          '&exclusive=' +
          exclusive
        if (is_dashboard) {
          url = url + '&dashboard=1&view=' + $container.data('view')
        }
        if(self.tl_request) self.tl_request.abort()
        self.tl_request = $.ajax({
          url: url,
          dataType: 'json',
          success: function(data) {
            items.add(data)
            self.tl_request = undefined
          }
        })
      }

      $('#tl_group')
        .on('change', function() {
          const fixedvals = $(this)
            .find(':selected')
            .data('fixedvals')
          if (fixedvals) {
            $('#tl_all_group_values_div').show()
          } else {
            $('#tl_all_group_values_div').hide()
          }
        })
        .trigger('change')

      return tl
    }

    setupTippy() {
      const $tippyElements = this.el.find('[data-tippy-content]')

      $tippyElements.each((i, tippyElement) => {
        const tippyEl = new TippyComponent(tippyElement)
        const wrapperEl = tippyElement.closest('.vis-group')

        tippyEl.initTippy(wrapperEl)
      })
    }

    snapToDay(datetime) {
      // A bit of a mess, as the input to this function is in the browser's
      // local timezone, but we need to return it from the function in UTC.
      // Pull the UTC values from the local date, and then construct a new
      // moment using those values.
      const year = datetime.getUTCFullYear()
      const month = ("0" + (datetime.getUTCMonth() + 1)).slice(-2)
      const day = ("0" + datetime.getUTCDate()).slice(-2)
      return moment.utc("" + year + month + day)
    }
    
    // If the perceived background color is dark, switch the font color to white.
    injectContrastingColor(dataset) {
      const self = this

      dataset.forEach(function(entry) {
        if (entry.style && typeof entry.style === 'string') {
          const backgroundColorMatch = entry.style.match(
            /background-color:\s(#[0-9A-Fa-f]{6})/
          )
          if (backgroundColorMatch && backgroundColorMatch[1]) {
            const backgroundColor = backgroundColorMatch[1]
            const backgroundColorLightOrDark = self.lightOrDark(backgroundColor)
            if (backgroundColorLightOrDark === 'dark') {
              entry.style = `
                ${entry.style};
                color: #FFFFFF;
                text-shadow:-1px -1px 0.1em ${backgroundColor},
                  1px -1px 0.1em ${backgroundColor},
                  -1px 1px 0.1em ${backgroundColor},
                  1px 1px 0.1em ${backgroundColor},
                  1px 1px 2px ${backgroundColor},
                  0 0 1em ${backgroundColor},
                  0 0 0.2em ${backgroundColor};`
            }
          }
        }
      })
    }

    /**
   * This function takes a color (hex) as the argument, calculates the color’s HSP value, and uses that
   * to determine whether the color is light or dark.
   * Source: https://awik.io/determine-color-bright-dark-using-javascript/
   *
   * @param {string} color
   * @returns {string}
   */
  lightOrDark(color) {
    // Convert it to HEX: http://gist.github.com/983661
    const hexColor = +(
      '0x' + color.slice(1).replace(color.length < 5 && /./g, '$&$&')
    )
    const r = hexColor >> 16
    const g = (hexColor >> 8) & 255
    const b = hexColor & 255

    // HSP (Perceived brightness) equation from http://alienryderflex.com/hsp.html
    const hsp = Math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b))

    // Using the HSP value, determine whether the color is light or dark.
    // The source link suggests 127.5, but that seems a bit too low.
    if (hsp > 150) {
      return 'light'
    }
    return 'dark'
  }
}

export default TimelineComponent
