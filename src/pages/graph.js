const GraphPage = () => {
  $("#is_shared")
    .change(function() {
      $("#group_id_div").toggle(this.checked);
    })
    .change();
  $(".date-grouping")
    .change(function() {
      if (
        $("#trend").val() ||
        $("#set_x_axis")
          .find(":selected")
          .data("is-date")
      ) {
        $("#x_axis_date_display").show();
      } else {
        $("#x_axis_date_display").hide();
      }
    })
    .change();
  $("#trend")
    .change(function() {
      if ($(this).val()) {
        $("#group_by_div").hide();
      } else {
        $("#group_by_div").show();
      }
    })
    .change();
  $("#x_axis_range")
    .change(function() {
      if ($(this).val() == "custom") {
        $("#custom_range").show();
      } else {
        $("#custom_range").hide();
      }
    })
    .change();
  $("#y_axis_stack")
    .change(function() {
      if ($(this).val() == "sum") {
        $("#y_axis_div").show();
      } else {
        $("#y_axis_div").hide();
      }
    })
    .change();
};

export { GraphPage };
