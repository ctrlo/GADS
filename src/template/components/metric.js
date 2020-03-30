const setupMetricModal = context => {
  const modalEl = $("#modal_metric", context);
  if (!modalEl.length) return;
  modalEl.on("show.bs.modal", event => {
    var button = $(event.relatedTarget);
    var metric_id = button.data("metric_id");
    $("#metric_id", context).val(metric_id);
    if (metric_id) {
      $("#delete_metric", context).show();
    } else {
      $("#delete_metric", context).hide();
    }
    var target_value = button.data("target_value");
    $("#target_value", context).val(target_value);
    var x_axis_value = button.data("x_axis_value");
    $("#x_axis_value", context).val(x_axis_value);
    var y_axis_grouping_value = button.data("y_axis_grouping_value");
    $("#y_axis_grouping_value", context).val(y_axis_grouping_value);
  });
};

const setup = context => {
  setupMetricModal(context);
};

export default setup;
