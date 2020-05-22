import { setupOtherUserViews } from "../components/other-user-view";
import { setupHoverableTable } from "../components/hoverable-table";

const DataTablePage = () => {
  setupHoverableTable();
  setupOtherUserViews();

  $('#modal_sendemail').on('show.bs.modal', function (event) {
      var button = $(event.relatedTarget);
      var peopcol_id = button.data('peopcol_id');
      $('#modal_sendemail_peopcol_id').val(peopcol_id);
  });

  $("#data-table").floatThead({
      floatContainerCss: {},
      zIndex: function($table){
          return 999;
      },
      ariaLabel: function($table, $headerCell, columnIndex) {
          return $headerCell.data('thlabel');
      }
  });

  if (!FontDetect.isFontLoaded('14px/1 FontAwesome')) {
      $( ".use-icon-font" ).hide();
      $( ".use-icon-png" ).show();
  }

  $('#rows_per_page').on('change', function() {
      this.form.submit();
  });
}

export { DataTablePage };
