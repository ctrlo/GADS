const setupUserPermission = (() => {
  const setupModalNew = context => {
    $("#modalnewtitle", context).on("hidden.bs.modal", () => {
      $("#newtitle", context).val("");
    });
    $("#modalneworganisation", context).on("hidden.bs.modal", () => {
      $("#neworganisation", context).val("");
    });
  };

  const setupCloneAndRemove = context => {
    $(document, context).on("click", ".cloneme", function() {
      var parent = $(this).parents(".limit-to-view");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
    });
    $(document, context).on("click", ".removeme", function() {
      var parent = $(this).parents(".limit-to-view");
      if (parent.siblings(".limit-to-view").length > 0) {
        parent.remove();
      }
    });
  };

  return context => {
    setupModalNew(context);
    setupCloneAndRemove(context);
  };
})()

export { setupUserPermission };
