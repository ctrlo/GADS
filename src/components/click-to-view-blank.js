import { setupZebraTable } from "../components/zebra-table";

const setupClickToViewBlank = (() => {
  // Used to hide and then display blank fields when viewing a record
  var setupClickToViewBlank = function(context) {
    $(".click-to-view-blank", context).on("click", function() {
      var showBlankFields = this.innerHTML === "Show blank values";
      $(".click-to-view-blank-field", context).toggle(showBlankFields);
      this.innerHTML = showBlankFields
        ? "Hide blank values"
        : "Show blank values";
      setupZebraTable(context);
    });
  };

  return context => {
    setupClickToViewBlank(context);
  };
})();

export { setupClickToViewBlank };
