const setupSelectAll = context => {
  $("#selectall", context).click(function() {
    $(".record_selected", context).prop("checked", this.checked);
  });
};

const setup = context => {
  setupSelectAll(context);
};

export default setup;
