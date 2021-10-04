const setupOtherUserViews = (() => {
  var setupOtherUserViews = function() {
    var layout_identifier = $("body").data("layout-identifier");
    var url = layout_identifier ? "/" + layout_identifier + "/match/user/" : "/match/user/";
    $("#views_other_user_typeahead").typeahead({
      delay: 500,
      matcher: function() {
        return true;
      },
      sorter: function(items) {
        return items;
      },
      afterSelect: function(selected) {
        $("#views_other_user_id").val(selected.id);
      },
      source: function(query, process) {
        return $.ajax({
          type: "GET",
          url: url,
          data: { q: query },
          success: function(result) {
            process(result);
          },
          dataType: "json"
        });
      }
    });
  };

  return context => {
    setupOtherUserViews(context);
  };
})();

export { setupOtherUserViews };
