const setupPurge = (() => {
  const setupSelectAll = context => {
    $("#selectall", context).click(function() {
      $(".record_selected", context).prop("checked", this.checked);
    });
  };

  return context => {
    setupSelectAll(context);
  };
})()

export { setupPurge };
