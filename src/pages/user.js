import { setupDataTables } from "../components/data-tables";

const UserPage = context => {
  setupDataTables(context);

  $(document).on("click", ".cloneme-user", function() {
    var parent = $(this).parents(".limit-to-view");
    var cloned = parent.clone();
    cloned.removeAttr("id").insertAfter(parent);
  });
  $(document).on("click", ".removeme-user", function() {
    var parent = $(this).parents(".limit-to-view");
    if (parent.siblings(".limit-to-view").length > 0) {
      parent.remove();
    }
  });
};

export { UserPage };
