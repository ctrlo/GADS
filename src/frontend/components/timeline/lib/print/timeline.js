/**
 * This function takes a color (hex) as the argument, calculates the color’s HSP value, and uses that
 * to determine whether the color is light or dark.
 * Source: https://awik.io/determine-color-bright-dark-using-javascript/
 *
 * @param {string} color
 * @returns {string}
 */
function lightOrDark(color) {
  // Convert it to HEX: http://gist.github.com/983661
  const hexColor = +(
    "0x" + color.slice(1).replace(color.length < 5 && /./g, "$&$&")
  );
  const r = hexColor >> 16;
  const g = (hexColor >> 8) & 255;
  const b = hexColor & 255;

  // HSP (Perceived brightness) equation from http://alienryderflex.com/hsp.html
  const hsp = Math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b));

  // Using the HSP value, determine whether the color is light or dark.
  // The source link suggests 127.5, but that seems a bit too low.
  if (hsp > 150) {
    return "light";
  }
  return "dark";
}

/**
 * this function retrieves the css value of a property in pixels from a supplied html node, as an integer
 *
 * @param {*} node
 * @param {string} property
 * @returns {number}
 */
function getCssPxValue(node, property = 'height') {
  if (!node || !node.length) {
    return 0;
  }

  try {
    const value = node.css(property);
    return value ? parseFloat(parseFloat(value.replace('px')).toFixed(4)) : 0;
  } catch (e) {
    console.error('fatal error', e);
    return 0;
  }
}

/**
 * This function finds and returns the label belonging to a .vis-group
 *
 * @param {number} groupTop
 * @returns {null|{node: *|null, text: string}}
 */
function getVisGroupLabelNode(groupTop) {
  const labels = $(".vis-label:visible");
  let label = null;

  labels.each(function () {
    let top = $(this).offset().top;
    top = top === 0 ? getCssTransformCoordinates($(this)).y : top;

    if (Math.floor(top) === groupTop) {
      label = $(this);
    }
  });

  return !label
    ? null
    : {
      node: label,
      text:
        label
          .find(".vis-inner")
          .first()
          .html() || ""
    };
}

/**
 * This function uses the CSS transform value of a VisJS object to determine the X and/or Y coordinate offset of
 * @param obj
 * @returns {{x: number, y: number}}
 */
function getCssTransformCoordinates(obj) {
  const transformMatrix = obj.css("-webkit-transform") ||
    obj.css("-moz-transform") ||
    obj.css("-ms-transform") ||
    obj.css("-o-transform") ||
    obj.css("transform");

  const matrix = transformMatrix.replace(/[^0-9\-.,]/g, '').split(',');
  const x = matrix[12] || matrix[4]; //translate x
  const y = matrix[13] || matrix[5]; //translate y

  return { x: parseFloat(x), y: parseFloat(y) };
}

/**
 * finds all .vis-item nodes under a .vis-group and groups them per row based on the
 * 'top' CSS propery of the item. These items are positioned absolute.
 *
 * @param {*} group
 * @returns {*}
 */
function getVisItemRowsInGroup(group) {
  let itemRows = [];
  let itemCache = {};
  let topCache = [];
  const items = group.find(".vis-item:visible");

  items.each(function () {
    let top = getCssPxValue($(this), "top");
    const coordinates = getCssTransformCoordinates($(this));
    top = top === 0 ? coordinates.y : top;

    if ($.inArray(top, topCache) === -1) {
      topCache.push(top);
    }

    if (!itemCache[top]) {
      itemCache[top] = [];
    }

    itemCache[top].push({
      node: $(this),
      label: $(this).find(".timeline-tippy").html().trim(),
      width: getCssPxValue($(this), 'width'),
      x: coordinates.x,
      y: coordinates.y,
      top: top,
      textColor: $(this).css('color') ? $(this).css('color') : false,
      backgroundColor: $(this).css('background-color')
    });
  });

  topCache.sort(function (a, b) { return a > b ? 1 : -1 });
  $.each(topCache, function (index, top) {
    itemRows.push(itemCache[top]);
  });

  return itemRows;
}

/**
 * this function retrieves a .vis-group thats in the foreground scope, and extracts the
 * required parameters. It matches a .vis-group in the background scope based on its
 * height, and a label based on its top offset. Items inside the group are collected
 * and sorted by row.
 *
 * @param {*} group
 * @returns {{backgroundGroup: *, node, itemRows: *, top, label: *, height: (number|number)}}
 */
function getVisGroup(group) {
  let top = Math.floor(group.offset().top);
  const height = getCssPxValue(group, "height");
  const itemRows = getVisItemRowsInGroup(group);

  top = top === 0 ? getCssTransformCoordinates(group).y : top;

  return {
    node: group,
    top: top,
    height: height,
    label: getVisGroupLabelNode(top),
    itemRows: itemRows
  };
}

/**
 * this function collects all vis-groups and prepares them for usage.
 *
 * @returns {*}
 */
function getVisGroups() {
  const groups = $(".vis-foreground .vis-group:visible");
  const visGroups = {};

  if (!groups || groups.length === 0) {
    return visGroups;
  }

  groups.each(function () {
    if ($(this).html()) {
      const group = getVisGroup($(this));

      visGroups[group.top] = group;
    }
  });

  return visGroups;
}

/**
 * this function reads the data objects of the VisJS timeline, to send to the PDF printer.
 * This solution has been added to address the issue where printing the VisJS HTML through
 * headless chrome in the backend, caused timeline items to collide when they fell over the
 * end of a page.
 *
 * see: https://brass.ctrlo.com/issue/805
 */
function parseTimelineForPdfPrinting() {
  // timeline item positions (.vis-item) are calculated per group (.vis-group),
  // positioned absolute from the top of the group. The group is dynamic in height.
  const visGroups = getVisGroups();

  if (Object.keys(visGroups).length !== 0) {
    parseVisGroups(visGroups);
  }
}

/**
 * This function returns an object property based on its key index
 * @param obj
 * @param key
 * @returns mixed
 */
function getObjectPropertyByOrderKey(obj, key = 0) {
  return obj[Object.keys(obj)[key]] || null;
}

/**
 * This function returns the first property value of an object, similar to jquery .first()
 * @param obj
 */
function getFirst(obj) {
  return getObjectPropertyByOrderKey(obj, 0);
}

/**
 * This function converts the item rows of a group to the JSON format used by the PDF printer.
 * @param itemRow
 * @returns {string}
 */
function renderGroupRowItemsJson(itemRow) {
  let itemsJson = '';

  $.each(itemRow, function (index, item) {
    itemsJson +=
      (itemsJson === '' ? '' : ',') +
      '{' +
      'x: ' + item.x + ', ' +
      'width: ' + item.width + ', ' +
      'text: "' + item.label.trim() + '", ' +
      'top: ' + item.top + ', ' +
      'textColor: "' + item.textColor + '", ' +
      'backgroundColor: "' + item.backgroundColor + '"' +
      ' }'
  });

  return itemsJson;
}

/**
 * This function converts a row of a group to the JSON format used by the PDF printer.
 * @param itemRows
 * @returns {string}
 */
function renderGroupRowsJson(itemRows) {
  let itemRowsJson = '';

  $.each(itemRows, function (index, itemRow) {
    itemRowsJson +=
      (itemRowsJson === '' ? '' : ',') +
      '{items: [' + renderGroupRowItemsJson(itemRow) + ']}'
  });

  return itemRowsJson;
}

/**
 * This function converts a group to the JSON format used by the PDF printer.
 * @param visGroups
 * @returns {string}
 */
function renderGroupsJson(visGroups) {
  let groupsJson = '';

  $.each(visGroups, function (index, visGroup) {
    groupsJson +=
      (groupsJson === '' ? '' : ',') +
      '{label: "' + visGroup.label.text + '", rows: [' + renderGroupRowsJson(visGroup.itemRows) + ']}';
  });

  return 'groups: [' + groupsJson + ']';
}

/**
 * This function converts all vis-minor nodes on the top X axis of the timeline to the JSON format used by the
 * PDF printer. When fromX and/or toX is provided, only the nodes in between those X values will be returned.
 * When the first vis-major node is processed, fromX is suspended. This is done because the first node can
 * contain labels that start before the fromX position.
 * @param xAxis
 * @param fromX
 * @param toX
 * @param firstMajor
 * @returns {string}
 */
function renderXAxisMinorsJson(xAxis, fromX = false, toX = false, firstMajor = true) {
  const minorObjects = xAxis.find('.vis-text.vis-minor:not(.vis-measure)');
  let minorsObjectJson = '';

  if (toX !== false) {
    toX = toX - 1;
  }

  $.each(minorObjects, function () {
    const minor = $(this);
    const coordinates = getCssTransformCoordinates(minor);

    // skip minor labels that do not belong to the current major label when the start and end X position of the major
    // label is provided
    if (fromX !== false) {
      // first major label can have a partial first minor label that is on a lower X position than the major label
      if (firstMajor && toX !== false && coordinates.x >= toX) {
        return true;
      }
      else if (!firstMajor && (coordinates.x < fromX || (toX !== false && coordinates.x >= toX))) {
        return true;
      }
    }

    const minorWidth = getCssPxValue(minor, 'width');
    const minorText = minor.html();

    minorsObjectJson +=
      (minorsObjectJson === '' ? '' : ',') +
      '{x: ' + coordinates.x + ', width: ' + minorWidth + ', text: "' + minorText + '"}';
  });

  return '[' + minorsObjectJson + ']';
}

/**
 * This function gathers and orders the major nodes of the VisJS timeline so that they are
 * returned in chronological order.
 * @param xAxis
 * @returns {*[]}
 */
function getOrderedMajors(xAxis) {
  const majorObjects = xAxis.find('.vis-text.vis-major:not(.vis-measure)');
  let orderedObjects = [];

  majorObjects.each(function () {
    orderedObjects.push({
      node: $(this),
      x: getCssTransformCoordinates($(this)).x,
      x_end: false
    });
  });

  orderedObjects.sort(function (a, b) { return a.x > b.x ? 1 : -1 });
  orderedObjects.reverse();

  let prevX = false;

  $(orderedObjects).each(function (index, value) {
    orderedObjects[index].x_end = prevX;
    prevX = orderedObjects[index].x;
  });

  orderedObjects.reverse();

  return orderedObjects;
}

/**
 * This function converts all vis-major nodes on the top X axis of the timeline to the JSON format used by the PDF printer.
 * @param xAxis
 * @returns {string}
 */
function renderXAxisMajorsJson(xAxis) {
  const majorObjects = getOrderedMajors(xAxis);
  let majorsObjectJson = '';

  if (majorObjects && majorObjects.length) {
    $.each(majorObjects, function (index, majorObject) {
      const majorText = majorObject.node.find('div').first().html();
      const minorsJson = renderXAxisMinorsJson(xAxis, majorObject.x, majorObject.x_end, index === 0);
      majorsObjectJson +=
        (majorsObjectJson === '' ? '' : ',') +
        '{text: "' + majorText + '", x: ' + majorObject.x + ', minor: ' + minorsJson + '}';
    });
  }
  else {
    majorsObjectJson += '{text: "", x: ' + majorObject.x + ', minor: ' + renderXAxisMinorsJson(xAxis) + '}';
  }

  return '[' + majorsObjectJson + ']';
}

/**
 * This function converts all information on the X Axis of the VisJS timeline to the JSON format used by the PDF printer.
 * @param xAxis
 * @returns {string}
 */
function renderXAxisJson(xAxis) {
  const firstXAxisMinor = xAxis.find('.vis-text.vis-minor:not(.vis-measure)').first();
  const firstXAxisCorrection = getCssTransformCoordinates(firstXAxisMinor).x;

  return 'xAxis: {' +
    'height: tableXAxisBarHeight,' +
    'x: ' + firstXAxisCorrection + ',' +
    'major: ' + renderXAxisMajorsJson(xAxis) +
    '}';
}

function parseVisGroups(visGroups) {
  const targetField = $('#html').first();
  const timeline = $('.vis-timeline').first();
  const xAxis = $(".vis-time-axis.vis-foreground").first();
  const yAxis = $(".vis-panel.vis-left").first();
  const firstXAxisMinor = xAxis.find('.vis-text.vis-minor:not(.vis-measure)').first();
  const firstGroup = getFirst(visGroups) || false;
  const firstRow = firstGroup ? getFirst(firstGroup.itemRows) : false;
  const firstItem = firstRow && firstRow[0] && firstRow[0].node ? firstRow[0].node : false;
  const firstItemContent = firstItem ? firstItem.find('.vis-item-content').first() : false;
  const firstYAxisLabel = $(".vis-label:visible").first();
  const currentTime = $(".vis-current-time");
  const showYAxisBar = getCssPxValue(firstYAxisLabel, 'width') > 0 ? 'true' : 'false';
  const canvasWidth = getCssPxValue(timeline, 'width');
  const fitToPageWidth = $('#fit_to_page_width').prop('checked');
  const zoomLevel = parseInt($('#pdf_zoom').val(), 10);

  const urlJS = targetField.data('url-js');
  const urlCSS = targetField.data('url-css');
  const pageWidth = 1550; // A3 width
  const zoomFactor = zoomLevel / 100 > 0 ? zoomLevel / 100 : 1;
  const pageWidthFactor = fitToPageWidth && pageWidth / canvasWidth > 0 ? pageWidth / canvasWidth : 1;
  const pageScaleFactor = fitToPageWidth ? pageWidthFactor : zoomFactor;
  const fontSize = getCssPxValue(firstItem, 'font-size');
  const lineHeight = getCssPxValue(firstItem, 'line-height');
  const tableXAxisBarHeight = getCssPxValue(xAxis, "height");
  const tableYAxisBarWidth = getCssPxValue(yAxis, "width");
  const borderSize = getCssPxValue(firstItem, 'border-top-width');
  const padding = getCssPxValue(firstItemContent, 'padding-top');
  const xAxisPadding = getCssPxValue(firstXAxisMinor, 'padding-top');
  const currentTimeX = currentTime.length ? getCssTransformCoordinates(currentTime.first()).x : -1;
  const pageData = '{' + renderXAxisJson(xAxis) + ',' + renderGroupsJson(visGroups) + '}';

  $('input#html').val(`<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>Data</title>
    <script type="application/javascript" src="${urlJS}/jquery-3.5.1.min.js"></script>
    <script type="application/javascript" src="${urlJS}/pdf_printer.js"></script>
    <link rel="stylesheet" type="text/css" href="${urlCSS}/pdf_printer.css">
    <link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Open+Sans">
  </head>
  <body>
    <script type="application/javascript">
      const pagePrefix = "page_";
      const pageHeight = 1086;
      const pageWidth = 1550;
      const pageScaleFactor = ${pageScaleFactor};
      const backgroundColor = "#fff";
      const foregroundColor = "#333";
      const xAxisMinorColor = "#ccc";
      const xAxisTextColor = "#4d4d4d";
      const currentTimeColor = "#ff7f6e";
      const font = "Open Sans";
      const fontSize = ${fontSize} * pageScaleFactor;
      const lineHeight = ${lineHeight} * pageScaleFactor;
      const tableXAxisBarHeight = ${tableXAxisBarHeight} * pageScaleFactor;
      const showYAxisBar = ${showYAxisBar};
      const tableYAxisBarWidth = showYAxisBar ? ${tableYAxisBarWidth} * pageScaleFactor : 0;
      const borderSize = ${borderSize} * pageScaleFactor;
      const padding = ${padding} * pageScaleFactor;
      const xAxisPadding = ${xAxisPadding} * pageScaleFactor;
      const currentTimeX = ${currentTimeX} * pageScaleFactor + tableYAxisBarWidth;
      const currentTimeThickness = 2 * pageScaleFactor;
      const pageData = ${pageData};
      let pageNumber = 0;
      let currentHeight = 0;
      let canvas = null;
      let context = null;

      drawTimelinePdf();
    </script>
  </body>
</html>`);
}

// If the perceived background color is dark, switch the font color to white.
const injectContrastingColor = function (dataset) {
  dataset.forEach(function (entry) {
    if (entry.style && typeof entry.style === "string") {
      const backgroundColorMatch = entry.style.match(
        /background-color:\s(#[0-9A-Fa-f]{6})/
      );
      if (backgroundColorMatch && backgroundColorMatch[1]) {
        const backgroundColor = backgroundColorMatch[1];
        const backgroundColorLightOrDark = lightOrDark(backgroundColor);
        if (backgroundColorLightOrDark === "dark") {
          entry.style =
            entry.style +
            ";" +
            "color: #FFFFFF;" +
            "text-shadow: " +
            "-1px -1px 0.1em " + backgroundColor +
            ",1px -1px 0.1em " + backgroundColor +
            ",-1px 1px 0.1em " + backgroundColor +
            ",1px 1px 0.1em " + backgroundColor +
            ",1px 1px 2px " + backgroundColor +
            ",0 0 1em " + backgroundColor +
            ",0 0 0.2em " + backgroundColor + ";";
        }
      }
    }
  });
};

const setupTimeline = function (container, options_in) {
  const records_base64 = container.data("records");
  const json = base64.decode(records_base64);
  const dataset = JSON.parse(json);
  injectContrastingColor(dataset);

  const items = new vis.DataSet(dataset);
  let groups = container.data("groups");
  const json_group = base64.decode(groups);
  groups = JSON.parse(json_group);
  const is_dashboard = !!container.data("dashboard");
  const layout_identifier = $("body").data("layout-identifier");

  // See http://visjs.org/docs/timeline/#Editing_Items
  const options = {
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
    orientation: { axis: "both" }
  };

  // Merge any additional options supplied
  for (const attrname in options_in) {
    options[attrname] = options_in[attrname];
  }

  if (container.data("min")) {
    options.start = container.data("min");
  }
  if (container.data("max")) {
    options.end = container.data("max");
  }

  if (container.data("width")) {
    options.width = container.data("width");
  }
  if (container.data("height")) {
    options.width = container.data("height");
  }

  if (!container.data("rewind")) {
    options.editable = {
      add: false,
      updateTime: true,
      updateGroup: false,
      remove: false
    };
    options.multiselect = true;
  }

  const tl = new vis.Timeline(container.get(0), items, options);
  if (groups.length > 0) {
    tl.setGroups(groups);
  }

  // functionality to add new items on range change
  let persistent_max;
  let persistent_min;
  tl.on("rangechanged", function (props) {
    if (!props.byUser) {
      if (!persistent_min) {
        persistent_min = props.start.getTime();
      }
      if (!persistent_max) {
        persistent_max = props.end.getTime();
      }
      return;
    }

    // Shortcut - see if we actually need to continue with calculations
    if (
      props.start.getTime() > persistent_min &&
      props.end.getTime() < persistent_max
    ) {
      update_range_session(props);
      return;
    }
    container.prev("#loading-div").show();

    /* Calculate the range of the current items. This will min/max
          values for normal dates, but for dateranges we need to work
          out the dates of what was retrieved. E.g. the earliest
          end of a daterange will be the start of the range of
          the current items (otherwise it wouldn't have been
          retrieved)
      */

    // Get date range with earliest start
    let val = items.min("start");
    // Get date range with latest start
    val = items.max("start");
    const max_start = val ? new Date(val.start) : undefined;
    // Get date range with earliest end
    val = items.min("end");
    const min_end = val ? new Date(val.end) : undefined;
    // If this is a date range without a time, then the range will have
    // automatically been altered to add an extra day to its range, in
    // order to show it across the expected period on the timeline (see
    // Timeline.pm). When working out the range to request, we have to
    // remove this extra day, as searching the database will not include it
    // and we will otherwise end up with duplicates being retrieved
    if (min_end && !val.has_time) {
      min_end.setDate(min_end.getDate() - 1);
    }
    // Get date range with latest end
    val = items.max("end");
    // Get earliest single date item
    val = items.min("single");
    const min_single = val ? new Date(val.single) : undefined;
    // Get latest single date item
    val = items.max("single");
    const max_single = val ? new Date(val.single) : undefined;

    // Now work out the actual range we have items for
    const have_range = {};
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
    let from;
    let to;
    if (!have_range.min) {
      from = props.start.getTime();
      to = props.end.getTime();
      load_items(from, to);
    }
    if (props.start < have_range.min) {
      from = props.start.getTime();
      to = have_range.min.getTime();
      load_items(from, to, "to");
    }
    if (props.end > have_range.max) {
      from = have_range.max.getTime();
      to = props.end.getTime();
      load_items(from, to, "from");
    }
    if (!persistent_max || persistent_max < props.end.getTime()) {
      persistent_max = props.end.getTime();
    }
    if (!persistent_min || persistent_min > props.start.getTime()) {
      persistent_min = props.start.getTime();
    }

    container.prev("#loading-div").hide();

    // leave to end in case of problems rendering this range
    update_range_session(props);
  });
  const csrf_token = $("body").data("csrf-token");
  /**
   * @param {object} props
   * @returns {void}
   */
  function update_range_session(props) {
    // Do not remember timeline range if adjusting timeline on dashboard
    if (!is_dashboard) {
      $.post({
        url: "/" + layout_identifier + "/data_timeline?",
        data:
          "from=" +
          props.start.getTime() +
          "&to=" +
          props.end.getTime() +
          "&csrf_token=" +
          csrf_token
      });
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
      "/" +
      layout_identifier +
      "/data_timeline/" +
      "10" +
      "?from=" +
      from +
      "&to=" +
      to +
      "&exclusive=" +
      exclusive;
    if (is_dashboard) {
      url = url + "&dashboard=1&view=" + container.data("view");
    }
    $.ajax({
      async: false,
      url: url,
      dataType: "json",
      success: function (data) {
        items.add(data);
      }
    });
  }

  $("#tl_group")
    .on("change", function () {
      const fixedvals = $(this)
        .find(":selected")
        .data("fixedvals");
      if (fixedvals) {
        $("#tl_all_group_values_div").show();
      } else {
        $("#tl_all_group_values_div").hide();
      }
    })
    .trigger("change");

  return tl;
};

// timeline PDF printer actions
$(document).ready(function () {
  const printModal = $("#modal_pdf");

  if (printModal.length) {
    const printForm = printModal.find('form').first();
    const fitToPageField = $('#fit_to_page_width').first();
    const zoomField = $('#pdf_zoom').first();

    // add toggle settings for zoom and fit to page functions. You can either zoom, or make the timeline fit to the
    // width of the page, but not both at the same time.
    fitToPageField.change(function () {
      if ($(this).is(":checked")) {
        zoomField.data('original-value', zoomField.val());
        zoomField.val(100);
        zoomField.prop('disabled', true);
      } else {
        const originalFieldValue = parseInt(zoomField.data('original-value'), 10);
        zoomField.val(originalFieldValue > 0 ? originalFieldValue : 100);
        zoomField.prop('disabled', false);
      }
    });

    // when the printing modal is submitted, scan the current timeline's structure, to send it to the PDF printer
    printForm.submit(function () {
      parseTimelineForPdfPrinting();
      return true;
    });
  }
});

export { setupTimeline };
