const MetricPage = () => {
  $("#modal_metric").on("show.bs.modal", function(event) {
    var button = $(event.relatedTarget);
    var metric_id = button.data("metric_id");
    $("#metric_id").val(metric_id);
    if (metric_id) {
      $("#delete_metric").show();
    } else {
      $("#delete_metric").hide();
    }
    var target_value = button.data("target_value");
    $("#target_value").val(target_value);
    var x_axis_value = button.data("x_axis_value");
    $("#x_axis_value").val(x_axis_value);
    var y_axis_grouping_value = button.data("y_axis_grouping_value");
    $("#y_axis_grouping_value").val(y_axis_grouping_value);
  });
};

export { MetricPage };
