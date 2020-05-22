const setupDataTables = (() => {
  var setupDataTables = function(context) {
    $(".dtable", context).each(function() {
      var pagelength = $(this).data("page-length") || 10;
      $(this).dataTable({
        order: [[1, "asc"]],
        pageLength: pagelength
      });
    });
  };

  return context => {
    setupDataTables(context);
  };
})();

export { setupDataTables };
