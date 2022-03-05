import { setupOtherUserViews } from "../components/other-user-view";

const AuditPage = () => {
  setupOtherUserViews();
  $("#views_other_user_typeahead").on("change", function() {
    $(this).val() || $("#views_other_user_id").val("")
  });
};

export { AuditPage };
