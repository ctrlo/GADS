const setupHoverableTable = (() => {
  var setupHoverableTable = function(context) {
    $(".table tr[data-href]", context).on("click", function() {
      window.location = $(this).data("href");
    });
  };

  return context => {
    setupHoverableTable(context);
  };
})();

export { setupHoverableTable };
