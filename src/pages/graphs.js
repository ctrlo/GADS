import { setupDataTables } from "../components/data-tables";

const GraphsPage = context => {
  setupDataTables(context);
  // When a search is entered in a datatables table, selected graphs that are
  // filtered will not be submitted. Therefore, find all selected values and
  // add them to the form
  $("#submit").on("click", function() {
    $(".dtable")
      .DataTable()
      .column(0)
      .nodes()
      .to$()
      .each(function() {
        var $cell = $(this);
        var $checkbox = $cell.find("input");
        if ($checkbox.is(":checked")) {
          $('<input type="hidden" name="graphs">')
            .val($checkbox.val())
            .appendTo("form");
        }
      });
  });
};

export { GraphsPage };
