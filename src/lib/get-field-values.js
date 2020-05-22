// get the value from a field, depending on its type
var getFieldValues = function($depends, filtered) {
  // If a field is not shown then treat it as a blank value (e.g. if fields
  // are in a hierarchy and the top one is not shown, or if the user does
  // not have write access to the field)
  if ($depends.length == 0 || $depends.css("display") == "none") {
    return [""];
  }

  var type = $depends.data("column-type");

  var values = [];
  var $visible;
  var $f;

  if (type === "enum" || type === "curval") {
    if (filtered) {
      $visible = $depends.find(".select-widget .available .answer");
      $visible.each(function() {
        var item = $(this).find('[role="option"]');
        values.push(item.text());
      });
    } else {
      $visible = $depends.find(
        ".select-widget .current [data-list-item]:not([hidden])"
      );
      $visible.each(function() {
        var item = $(this).hasClass("current__blank")
          ? ""
          : $(this).data("list-text");
        values.push(item);
      });
    }
  } else if (type === "person") {
    values = [$depends.find("option:selected").text()];
  } else if (type === "tree") {
    // get the hidden fields of the control - their textual value is located in a dat field
    $depends.find(".selected-tree-value").each(function() {
      values.push($(this).data("text-value"));
    });
  } else if (type === "daterange") {
    $f = $depends.find(".form-control");
    values = $f
      .map(function() {
        return $(this).val();
      })
      .get()
      .join(" to ");
  } else {
    $f = $depends.find(".form-control");
    values = [$f.val()];
  }

  // A multi-select field with no values selected should be the same as a
  // single-select with no values. Ensure that both are returned as a single
  // empty string value. This is important for display_condition testing, so
  // that at least one value is tested, even if it's empty
  if (values.length == 0) {
    values = [""];
  }

  return values;
};

export { getFieldValues };
