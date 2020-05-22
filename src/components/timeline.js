// This function takes a color (hex) as the argument, calculates the color’s HSP value, and uses that
// to determine whether the color is light or dark.
// Source: https://awik.io/determine-color-bright-dark-using-javascript/
function lightOrDark(color) {
    // Convert it to HEX: http://gist.github.com/983661
    var hexColor = +("0x" + color.slice(1).replace(color.length < 5 && /./g, "$&$&"));
    var r = hexColor >> 16;
    var g = hexColor >> 8 & 255;
    var b = hexColor & 255;

    // HSP (Perceived brightness) equation from http://alienryderflex.com/hsp.html
    var hsp = Math.sqrt(
        0.299 * (r * r) +
        0.587 * (g * g) +
        0.114 * (b * b)
    );

    // Using the HSP value, determine whether the color is light or dark.
    // The source link suggests 127.5, but that seems a bit too low.
    if (hsp > 150) {
        return "light";
    } else {
        return "dark";
    }
}

// If the perceived background color is dark, switch the font color to white.
var injectContrastingColor = function(dataset) {
    dataset.forEach(function(entry) {
        if (entry.style && typeof(entry.style) === "string") {
            var backgroundColorMatch = entry.style.match(/background-color:\s(#[0-9A-Fa-f]{6})/);
            if (backgroundColorMatch && backgroundColorMatch[1]) {
                var backgroundColor = backgroundColorMatch[1];
                var backgroundColorLightOrDark = lightOrDark(backgroundColor);
                if (backgroundColorLightOrDark === "dark") {
                    entry.style = entry.style + ";" + " color: #FFFFFF";
                }
            }
        }
    });
}

var setupTimeline = function (container, options_in) {
  var records_base64 = container.data('records');
  var json = base64.decode(records_base64);
  var dataset = JSON.parse(json);
  injectContrastingColor(dataset);

  var items = new vis.DataSet(dataset);
  var groups = container.data('groups');
  var json_group = base64.decode(groups);
  var groups = JSON.parse(json_group);
  var is_dashboard = container.data('dashboard') ? true : false;

  var layout_identifier = $('body').data('layout-identifier');

  // See http://visjs.org/docs/timeline/#Editing_Items
  var options = {
      margin: {
          item: {
              horizontal: -1
          }
      },
      moment: function (date) {
          return moment(date).utc();
      },
      clickToUse: is_dashboard,
      zoomFriction: 10,
      template: Handlebars.templates.timelineitem,
      orientation: {axis: "both"}
  };

  // Merge any additional options supplied
  for (var attrname in options_in) { options[attrname] = options_in[attrname]; }

  if (container.data('min')) {
      options.start = container.data('min');
  }
  if (container.data('max')) {
      options.end = container.data('max');
  }

  if (container.data('width')) {
      options.width = container.data('width');
  }
  if (container.data('height')) {
      options.width = container.data('height');
  }

  if (!container.data('rewind')) {
      options.editable = {
          add:         false,
          updateTime:  true,
          updateGroup: false,
          remove:      false
      };
      options.multiselect = true;
  }

  var tl = new vis.Timeline(container.get(0), items, options);
  if (groups.length > 0) {
      tl.setGroups(groups);
  }

  // functionality to add new items on range change
  var persistent_max;
  var persistent_min;
  tl.on('rangechanged', function (props) {
      if (!props.byUser) {
          if (!persistent_min) { persistent_min = props.start.getTime(); }
          if (!persistent_max) { persistent_max = props.end.getTime(); }
          return;
      }

      // Shortcut - see if we actually need to continue with calculations
      if (props.start.getTime() > persistent_min && props.end.getTime() < persistent_max) {
          update_range_session(props);
          return;
      }
      container.prev('#loading-div').show();

      /* Calculate the range of the current items. This will min/max
          values for normal dates, but for dateranges we need to work
          out the dates of what was retrieved. E.g. the earliest
          end of a daterange will be the start of the range of
          the current items (otherwise it wouldn't have been
          retrieved)
      */

      // Get date range with earliest start
      var val = items.min('start');
      var min_start = val ? new Date(val.start) : undefined;
      // Get date range with latest start
      val = items.max('start');
      var max_start = val ? new Date(val.start) : undefined;
      // Get date range with earliest end
      val = items.min('end');
      var min_end = val ? new Date(val.end) : undefined;
      // If this is a date range without a time, then the range will have
      // automatically been altered to add an extra day to its range, in
      // order to show it across the expected period on the timeline (see
      // Timeline.pm). When working out the range to request, we have to
      // remove this extra day, as searching the database will not include it
      // and we will otherwise end up with duplicates being retrieved
      if (min_end && !val.has_time) {
          min_end.setDate(min_end.getDate()-1);
      }
      // Get date range with latest end
      val = items.max('end');
      var max_end = val ? new Date(val.end) : undefined;
      // Get earliest single date item
      val = items.min('single');
      var min_single = val ? new Date(val.single) : undefined;
      // Get latest single date item
      val = items.max('single');
      var max_single = val ? new Date(val.single) : undefined;

      // Now work out the actual range we have items for
      var have_range = {};
      if (min_end && min_single) {
          // Date range items and single date items
          have_range.min = min_end < min_single ? min_end : min_single;
      } else {
          // Only one or the other
          have_range.min = min_end || min_single;
      }
      if (max_start && max_single) {
          // Date range items and single date items
          have_range.max = max_start > max_single ? max_start : max_single;
      } else {
          // Only one or the other
          have_range.max = max_start || max_single;
      }
      /* haverange now contains the min and max of the current
          range. Now work out whether we need to fill to the left or
          right (or both)
      */
      if (!have_range.min) {
          var from = props.start.getTime();
          var to = props.end.getTime();
          load_items(from, to);
      }
      if (props.start < have_range.min) {
          var from = props.start.getTime();
          var to = have_range.min.getTime();
          load_items(from, to, "to");
      }
      if (props.end > have_range.max) {
          var from = have_range.max.getTime();
          var to = props.end.getTime();
          load_items(from, to, "from");
      }
      if (!persistent_max || persistent_max < props.end.getTime()) {
          persistent_max = props.end.getTime();
      }
      if (!persistent_min || persistent_min > props.start.getTime()) {
          persistent_min = props.start.getTime();
      }

      container.prev('#loading-div').hide();

      // leave to end in case of problems rendering this range
      update_range_session(props);
  });
  var csrf_token = $('body').data('csrf-token');
  function update_range_session(props) {
      // Do not remember timeline range if adjusting timeline on dashboard
      if (!is_dashboard) {
          $.post({
              url: "/" + layout_identifier + "/data_timeline?",
              data: "from=" + props.start.getTime() + "&to=" + props.end.getTime() + "&csrf_token=" + csrf_token
          });
      }
  }

  function load_items(from, to, exclusive) {
      /* we use the exclusive parameter to not include ranges
          that go over that date, otherwise we will retrieve
          items that we already have */
      var url = "/" + layout_identifier + "/data_timeline/" + "10" + "?from=" + from + "&to=" + to + "&exclusive=" + exclusive;
      if (is_dashboard) {
          url = url + '&dashboard=1&view=' + container.data('view');
      }
      $.ajax({
          async: false,
          url: url,
          dataType:'json',
          success: function(data) {
              items.add(data);
          }
      });
  }

  return tl;
};

export { setupTimeline };
