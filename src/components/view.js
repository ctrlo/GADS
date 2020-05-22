const setupView = (() => {
  const setupSelectAll = context => {
    if (!$(".col_check", context).length) return;
    $("#selectall", context).click(event => {
      $(".col_check", context).prop("checked", event.currentTarget.checked);
    });
  };

  const setupGlobalChange = context => {
    $("#global", context)
      .change(event => {
        $("#group_id_div", context).toggle(event.currentTarget.checked);
      })
      .change();
  };

  const setupSorts = context => {
    const sortsEl = $("div#sorts", context);
    if (!sortsEl.length) return;
    sortsEl.on("click", ".closeme", event => {
      var c = $(".request-row").length;
      if (c < 1) return;
      $(event.currentTarget)
        .parents(".request-row")
        .remove();
    });
    sortsEl.on("click", ".add", event => {
      $(event.currentTarget)
        .parents(".sort-add")
        .before(sortsEl.data("sortrow"));
    });
  };

  const setupGroups = context => {
    const groupsEl = $("div#groups", context);
    if (!groupsEl.length) return;

    groupsEl.on("click", ".closeme", event => {
      if (!$(".request-row").length) return;
      $(event.currentTarget)
        .parents(".request-row")
        .remove();
    });
    groupsEl.on("click", ".add", event => {
      $(event.currentTarget)
        .parents(".group-add")
        .before(groupsEl.data("grouprow"));
    });
  };

  const setupFilter = context => {
    const builderEl = $("#builder", context);
    if (!builderEl.length) return;
    if (!builderEl.data("use-json")) return;
    var data = base64.decode(builderEl.data("base-filter"));
    builderEl.queryBuilder("setRules", JSON.parse(data));
  };

  const setupUpdateFilter = context => {
    $("#saveview", context).click(() => {
      var res = $("#builder", context).queryBuilder("getRules");
      $("#filter", context).val(JSON.stringify(res, null, 2));
    });
  };

  return context => {
    setupSelectAll(context);
    setupGlobalChange(context);
    setupSorts(context);
    setupGroups(context);
    setupFilter(context);
    setupUpdateFilter(context);
  };
})();

export { setupView };
