const setupZebraTable = (() => {
  var setupZebraTable = function(context) {
    $('.table--zebra', context).each(function(_, table) {
        var isOdd = true;
        $(table).children('tbody').children("tr:visible").each(function(_, tr) {
            $(tr).toggleClass("odd", isOdd);
            $(tr).toggleClass("even", !isOdd);
            isOdd = !isOdd;
        });
    });
  }

  return context => {
    setupZebraTable(context);
  };
})()

export { setupZebraTable };
