import { setupFontAwesome } from "./font-awesome";

const setupTable = (() => {
  const setupSendemailModal = context => {
    $("#modal_sendemail", context).on("show.bs.modal", event => {
      var button = $(event.relatedTarget);
      var peopcol_id = button.data("peopcol_id");
      $("#modal_sendemail_peopcol_id").val(peopcol_id);
    });
  };

  const setupHelptextModal = context => {
    $("#modal_helptext", context).on("show.bs.modal", event => {
      var button = $(event.relatedTarget);
      var col_name = button.data("col_name");
      $("#modal_helptext", context)
        .find(".modal-title")
        .text(col_name);
      var col_id = button.data("col_id");
      $.get("/helptext/" + col_id, data => {
        $("#modal_helptext", context)
          .find(".modal-body")
          .html(data);
      });
    });
  };

  const setupDataTable = context => {
    if (!$("#data-table", context).length) return;
    $("#data-table", context).floatThead({
      floatContainerCss: {},
      zIndex: () => 999,
      ariaLabel: ($table, $headerCell) => $headerCell.data("thlabel")
    });
  };

  return context => {
    setupSendemailModal(context);
    setupHelptextModal(context);
    setupDataTable(context);
    setupFontAwesome();
  };
})()

export { setupTable };
