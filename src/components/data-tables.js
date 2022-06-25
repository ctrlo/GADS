const setupDataTables = (() => {
  var setupDataTables = function(context) {
    $(".dtable", context).each(function() {
      var pagelength = $(this).data("page-length") || 10;
      var params = {
        order: [[1, "asc"]],
        pageLength: pagelength
      };
      var type = $(this).data("type");
      if (type == "users") {
        // Rendering function to produce HTML-encoded data from plain text
        var $render = function (data, type, row, meta) {
            if (type == "filter" || type == "sort" || type == "type") {
                return data;
            } else if (type == "display") {
                return $('<div />').text(data).html()
            } else {
                return data;
            }
        };
        params.ajax = '/api/users';
        params.serverSide = true;
        params.processing = true;
        params.columns = [
            {
                name: 'id',
                data: 'id',
                render: function (data, type, row, meta) {
                    if (type == "display") {
                        return '<a href="/user/' + data + '">' + data + '</a>';
                    } else {
                        return data;
                    }
                }
            },
            {
                name: 'surname',
                data: 'surname',
                render: $render
            },
            {
                name: 'firstname',
                data: 'firstname',
                render: $render
            },
            {
                name: 'title',
                data: 'title',
                render: $render
            },
            {
                name: 'email',
                data: 'email',
                render: $render
            },
            {
                name: 'organisation',
                data: 'organisation',
                render: $render
            },
            {
                name: 'created',
                data: 'created',
                render: $render
            },
            {
                name: 'lastlogin',
                data: 'lastlogin',
                render: $render
            },
        ];
      }
      $(this).dataTable(params);
    });
  };

  return context => {
    setupDataTables(context);
  };
})();

export { setupDataTables };
