// General function to format date as per backend
const format_date = function(date) {
  if (!date) return undefined;
  return {
    year:   date.getFullYear(),
    month:  date.getMonth() + 1, // JS returns 0-11, Perl 1-12
    day:    date.getDate(),
    hour:   0,
    minute: 0,
    second: 0,
    //yday: > $value->doy, // TODO
    epoch: date.getTime() / 1000,
  };
};

// get the value from a field, depending on its type
const getFieldValues = function($depends, filtered, for_code, form_value) {
  const type = $depends.data("column-type");

  // If a field is not shown then treat it as a blank value (e.g. if fields
  // are in a hierarchy and the top one is not shown, or if the user does
  // not have write access to the field).
  // At the moment do not do this for calc fields, as these are not currently
  // shown and therefore will always return blank. This may need to be
  // updated in the future in order to do something similar as normal fields
  // (returning blank if they themselves would not be shown under display
  // conditions)
  if ($depends.length == 0 || $depends.css("display") == "none") {
    if (type != "calc") {
      return [""];
    }
  }

  let values = [];
  let $f;
  if (type === "enum" || type === "curval" || type === "person") {
    if ($depends.data('value-selector') == "noshow") {
      $depends.find('.table-curval-group').find('input').each(function(){
        const item = $(this);
        values.push(item)
      });
    } else if (filtered) {
      // Field is type "filval". Therefore the values are any visible value in
      // the associated filtered drop-down
      let $visible = $depends.find(".select-widget .available .answer");
      $visible.each(function() {
        const item = $(this);
        values.push(item);
      });
    } else {
      let $visible = $depends.find(
        ".select-widget .current [data-list-item]:not([hidden])"
      );
      $visible.each(function() {
        const item = $(this).hasClass("current__blank")
          ? undefined
          : $(this);
        values.push(item);
      });
    }
    if (for_code) {
      if ($depends.data('is-multivalue')) {
        // multivalue
        const vals = $.map(values, function(item) {
          return {
            id:    item.data("list-id"),
            value: item.data("list-text")
          };
        });
        const plain = $.map(vals, function(item) {
          return item.value;
        });
        return {
          text: plain.join(', '),
          values: vals
        };
      } else {
        // single value
        if (values.length && values[0]) {
          return values[0].data("list-text");
        } else {
          return undefined;
        }
      }
    } else if (form_value) {
      values = $.map(values, function(item) {
        if (item) {
          // If this is a newly added item, return the form data instead of the
          // ID (which won't be saved yet)
          return item.data("list-id") || item.data("form-data");
        } else {
          return null;
        }
      });
    } else {
      values = $.map(values, function(item) {
        if (item) {
          return item.data("list-text");
        } else {
          return "";
        }
      });
    }
  } else if (type === "person") {
    values = [$depends.find("input").val()];
  } else if (type === "tree") {
    // get the hidden fields of the control - their textual value is located in a dat field
    $depends.find(".selected-tree-value").each(function() {
      if (form_value) {
        values.push($(this).val());
      } else {
        values.push($(this).data("text-value"));
      }
    });
  } else if (type === "daterange") {

    $f = $depends.find(".form-control");

    // Dateranges from the form are in pairs. Convert to single objects:
    let dateranges = [];
    let from_date;
    $f.each(function(index){
      if (index % 2 == 0) {
        // from date
        from_date = $(this);
      } else {
        // to date
        dateranges.push({
          from: from_date,
          to:   $(this)
        });
      }
    });

    if (for_code) {
      const codevals = dateranges.map(function(dr) {
        const from = dr.from.datepicker("getDate");
        const to   = dr.to.datepicker("getDate");
        if (!from || !to) {
          return undefined;
        }
        return {
          from:  format_date(from),
          to:    format_date(to),
          value: dr.from.val() + ' to ' + dr.to.val(),
        };
      });
      if ($depends.data('is-multivalue')) {
        return codevals;
      } else {
        return codevals[0];
      }
    } else if (form_value) {
      values = dateranges.map(function(dr) {
        return {
            from: dr.from.val(),
            to: dr.to.val()
        }
      })
    } else {
      values = dateranges.map(function(dr) {
        return dr.from.val() + ' to ' + dr.to.val();
      })
    }

  } else if (type === "date") {

    if ($depends.data('is-multivalue')) {
      values = $depends.find(".form-control").map(function(){
        const $df = $(this);
        return for_code ? format_date($df.datepicker("getDate")) : $df.val();
      }).get();
      if (for_code || form_value) {
        return values;
      }
    } else {
      const $df = $depends.find(".form-control");
      if (for_code || form_value) {
        return format_date($df.datepicker("getDate"));
      } else {
        values = [$df.val()];
      }
    }

  } else if (type === "file") {

    values = $depends.find("input:checkbox:checked").map(function(){
      if (form_value) {
        return {
            id: $(this).val(),
            filename: $(this).data('filename')
        }
      } else {
        return $(this).data('filename')
      }
    }).get();

  } else {
    // Can't use map as an undefined return value is skipped
    values = [];
    $depends.find(".form-control").each(function(){
        var $df = $(this);
        values.push($df.val().length ? $df.val() : undefined);
    });
    // Provide consistency with backend: single value is returned as scalar
    if (for_code && !$depends.data('is-multivalue')) {
        values = values.shift();
    }
  }

  // A multi-select field with no values selected should be the same as a
  // single-select with no values. Ensure that both are returned as a single
  // empty string value. This is important for display_condition testing, so
  // that at least one value is tested, even if it's empty
  if (Array.isArray(values) && values.length == 0) {
    values = [""];
  }

  return values;
};

export { getFieldValues };
