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
 * this retrieves the css value of a property in pixels from a supplied html node, as an integer
 *
 * @param {*} node
 * @param {string} property
 * @returns {number}
 */
function getCssPxValue(node, property) {
  if (!node || !node.length) {
    return 0;
  }

  property = !property ? "height" : property;
  const value = node.css(property);

  return value ? parseInt(value.replace("px"), 10) : 0;
}

/**
 * this function adds pixels to the css value of a property for a supplied html node.
 *
 * @param {*} node
 * @param {number} addPx
 * @param {string} property
 * @returns {void}
 */
function addCssPxValue(node, addPx, property) {
  if (!node || !node.length) {
    return;
  }

  property = !property ? "height" : property;
  addPx = !addPx ? 0 : parseInt(addPx, 10);
  const currentValue = getCssPxValue(node, property);
  const newValue = currentValue + addPx;

  node.css(property, newValue + "px");
}

/**
 * .vis-timeline's height cant be changed due to a redraw event that triggers when it is modified.
 * this is a workaround that corrects the print view styling so the PDF looks decent and all
 * elements are in the right place with the right size.
 *
 * @param {*} lastGroup
 * @returns {void}
 */
function correctPrintPositioningAndStyling(lastGroup) {
  const timeline = $(".vis-timeline");
  const topRuler = $(".vis-panel.vis-top");
  const bottomRuler = $(".vis-panel.vis-bottom");
  const leftBar = $(".vis-panel.vis-left");
  const centerContent = $(".vis-panel.vis-center");
  const groupContainer = $(".vis-itemset");
  const backgrounds = $(".vis-panel.vis-background");
  const monthLabels = $(".vis-panel.vis-bottom .vis-text.vis-minor");
  const yearLabels = $(".vis-panel.vis-bottom .vis-text.vis-major");

  // change CSS to compensate for timeline that can't be stretched.
  // styling will be slightly different, but uniform.
  timeline.css("overflow-x", "visible");
  timeline.css("overflow-y", "visible");
  timeline.css("border", "none");
  topRuler.css("border-top", "1px solid #c7c7c7");
  bottomRuler.css("border-bottom", "1px solid #c7c7c7");
  leftBar.css("border-left", "1px solid #c7c7c7");
  monthLabels.css("border-left", "1px solid #c7c7c7");
  yearLabels.css("border-left", "1px solid #c7c7c7");

  // calculate how much the items should be repositioned based of the last item row's
  // position (top + pixelsToNextRowTop). the offset is calculated towards the top
  // of the bottom ruler
  const lastItemRowOffsetTop = lastGroup.itemRows[
    Object.keys(lastGroup.itemRows)[Object.keys(lastGroup.itemRows).length - 1]
  ][0].offset().top;
  const currentOffset = bottomRuler.offset().top - lastItemRowOffsetTop;
  const correctOffsetWith = lastGroup.meta.pixelsToNextRowTop - currentOffset;

  addCssPxValue(centerContent, correctOffsetWith, "height");
  addCssPxValue(leftBar, correctOffsetWith, "height");
  addCssPxValue(groupContainer, correctOffsetWith, "height");
  addCssPxValue(backgrounds, correctOffsetWith, "height");
  addCssPxValue(bottomRuler, correctOffsetWith, "top");
}

/**
 * function corrects all vis.item nodes in a .vis-group node to the correct positioning and corrects the
 * group and label height to match the new positioning settings.
 *
 * @param {*} group
 * @returns {number}
 */
function correctPrintVisGroup(group) {
  if (!group || !group.itemRows || group.itemRows === {} || !group.meta) {
    return 0;
  }

  // A3 with 0.5cm margins = 19 + 1085 + 19 pixels, margins are skipped as they should not contain content.
  const pixelsPerPage = 1085;
  const firstItemNode = group.itemRows[group.meta.itemRowKeys[0]][0];
  let remainingPixelsOnPage =
    pixelsPerPage - (firstItemNode.offset().top % pixelsPerPage);
  let currentTop = group.meta.containerMargin;

  // loop through item row keys instead of itemRows, because the keys are sorted numerically ascending.
  // this order is not guaranteed for itemRows.
  $.each(group.meta.itemRowKeys, function(i, rowKey) {
    const wouldBeOnNewPage =
      remainingPixelsOnPage -
      group.meta.itemHeight -
      group.meta.containerMargin;

    // reset remaining pixels on page, and update the next row top parameter so that it falls on the next page
    if (wouldBeOnNewPage <= 0) {
      currentTop += remainingPixelsOnPage + group.meta.containerMargin;
      remainingPixelsOnPage = pixelsPerPage - group.meta.containerMargin;
    }

    $.each(group.itemRows[rowKey], function(itemKey, item) {
      item.css("top", currentTop + "px");
    });

    currentTop += group.meta.pixelsToNextRowTop;
    remainingPixelsOnPage -= group.meta.pixelsToNextRowTop;
  });

  currentTop += group.meta.containerMargin;

  group.node.css("height", currentTop + "px");

  // label is nog automatically stretched in the row, but styled separately.
  if (group.label && group.label.node) {
    group.label.node.css("height", currentTop + "px");
  }

  // the background group needs to stretch with the foreground group, as it doesnt automatically stretch.
  if (group.backgroundGroup && group.backgroundGroup.node) {
    group.backgroundGroup.node.css("height", currentTop + "px");
  }

  return currentTop;
}

/**
 * This function finds and returms the label belonging to a .vis-group
 *
 * @param {number} groupTop
 * @returns {null|{node: *|null, text: string}}
 */
function getVisGroupLabelNode(groupTop) {
  const labels = $(".vis-label:visible");
  let label = null;

  labels.each(function() {
    if ($(this).offset().top === groupTop) {
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
 * This function finds and returms the background group belonging to a .vis-group in the foreground based on the similar
 * height value
 *
 * @param {number} groupHeight
 * @returns {null|{node: *|null}}
 */
function getVisBackgroundGroup(groupHeight) {
  const backgroundGroups = $(
    ".vis-content .vis-itemset .vis-background .vis-group"
  );
  let backgroundGroup = null;

  backgroundGroups.each(function() {
    if (getCssPxValue($(this), "height") === groupHeight) {
      backgroundGroup = $(this);
    }
  });

  return !backgroundGroup
    ? null
    : {
        node: backgroundGroup
      };
}

/**
 * function calculates the start top pixels of the first row and the space that
 * each row takes.
 *
 * @param {*} itemRows
 * @returns {{containerMargin: number, itemRowKeys: string[], pixelsToNextRowTop: number, itemHeight: number}|null}
 */
function getItemRowsMeta(itemRows) {
  if (!itemRows || itemRows === {}) {
    return null;
  }

  const topKeys = Object.keys(itemRows);

  if (topKeys.length <= 1) {
    return null;
  }

  topKeys.sort((a, b) => a - b);

  return {
    containerMargin: parseInt(topKeys[0]),
    pixelsToNextRowTop: parseInt(topKeys[1] - topKeys[0], 10),
    itemHeight: Math.ceil(itemRows[topKeys[0]][0].height(), 10),
    itemRowKeys: topKeys
  };
}

/**
 * finds all .vis-item nodes under a .vis-group and groups them per row based on the
 * 'top' CSS propery of the item. These items are positioned absolute.
 *
 * @param {*} group
 * @returns {*}
 */
function getVisItemRowsInGroup(group) {
  const itemRows = {};
  const items = group.find(".vis-item:visible");

  items.each(function() {
    const top = getCssPxValue($(this), "top");

    if (!itemRows[top]) {
      itemRows[top] = [];
    }

    itemRows[top].push($(this));
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
 * @returns {{backgroundGroup: *, node, itemRows: *, top, meta: *, label: *, height: (number|number)}}
 */
function getVisForegroundGroup(group) {
  const top = group.offset().top;
  const height = getCssPxValue(group, "height");
  const itemRows = getVisItemRowsInGroup(group);

  return {
    node: group,
    top: top,
    height: height,
    label: getVisGroupLabelNode(top),
    backgroundGroup: getVisBackgroundGroup(group),
    itemRows: itemRows,
    meta: getItemRowsMeta(itemRows)
  };
}

/**
 * this function collects all vis-groups and prepares them for usage.
 *
 * @returns {*}
 */
function getFormattedVisGroups() {
  const groups = $(".vis-foreground .vis-group:visible");
  const formattedGroups = {};

  if (!groups || groups.length === 0) {
    return formattedGroups;
  }

  groups.each(function() {
    if ($(this).html()) {
      const group = getVisForegroundGroup($(this));

      formattedGroups[group.top] = group;
    }
  });

  return formattedGroups;
}

/**
 * this function corrects the printed bars of the timeline to prevent them from running
 * across two pages during PDF printing.
 */
function correctPrintView() {
  $(document).ready(function() {
    // timeline item potistions (.vis-item) are calculated per group (.vis-group),
    // positioned absolute from the top of the group. The group is dynamic in height,
    // so we need to re-calculate the space on the printable page per group from the top.
    const formattedGroups = getFormattedVisGroups();

    if (formattedGroups !== {}) {
      let lastGroup = null;

      $.each(formattedGroups, function(index, group) {
        correctPrintVisGroup(group);
        lastGroup = group;
      });

      // .vis-timeline's height cant be changed due to a redraw event that triggers when it is modified.
      // this is a workaround that corrects the print view styling so the PDF looks decent and all
      // elements are in the right place with the right size.
      correctPrintPositioningAndStyling(lastGroup);
    }
  });
}

// If the perceived background color is dark, switch the font color to white.
const injectContrastingColor = function(dataset) {
  dataset.forEach(function(entry) {
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
            "-1px -1px 0.1em " +
            backgroundColor +
            ",1px -1px 0.1em " +
            backgroundColor +
            ",-1px 1px 0.1em " +
            backgroundColor +
            ",1px 1px 0.1em " +
            backgroundColor +
            ",1px 1px 2px " +
            backgroundColor +
            ",0 0 1em " +
            backgroundColor +
            ",0 0 0.2em " +
            backgroundColor +
            ";";
        }
      }
    }
  });
};

const setupTimeline = function(container, options_in) {
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
    moment: function(date) {
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
  tl.on("rangechanged", function(props) {
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
      success: function(data) {
        items.add(data);
      }
    });
  }

  $("#tl_group")
    .on("change", function() {
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

// detect print view for PDF, then correct node placement of VisJS to
// avoid bars stretching over page breaks
const urlStr = $(location).attr("href") || "";

if (urlStr.toLowerCase().indexOf("pdf=1") > -1) {
  correctPrintView();
}

export { setupTimeline };
