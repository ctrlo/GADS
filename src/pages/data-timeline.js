import { setupOtherUserViews } from "../components/other-user-view";
import { setupTippy } from "../components/tippy";

const DataTimelinePage = () => {
  var save_elem_sel    = '#submit_button',
  cancel_elem_sel  = '#cancel_button',
  changed_elem_sel = '#visualization_changes',
  hidden_input_sel = '#changed_data';

  var changed = {};

  function on_move (item, callback) {
    changed[item.id] = item;

    var save_button = $( save_elem_sel );
    if ( save_button.is(':hidden') ) {
        $(window).bind('beforeunload', function(e) {
            var error_msg = 'If you leave this page your changes will be lost.';
            if (e) {
                e.returnValue = error_msg;
            }
            return error_msg;
        });

        save_button.closest('form').css('display', 'block');
    }

    var changed_item = $('<li>' + item.content + '</li>');
    $( changed_elem_sel ).append(changed_item);

    return callback(item);
  }

  function snap_to_day (datetime, scale, step) {
    // A bit of a mess, as the input to this function is in the browser's
    // local timezone, but we need to return it from the function in UTC.
    // Pull the UTC values from the local date, and then construct a new
    // moment using those values.
    var year = datetime.getUTCFullYear();
    var month = ("0" + (datetime.getUTCMonth() + 1)).slice(-2);
    var day = ("0" + datetime.getUTCDate()).slice(-2);
    return timeline.moment.utc('' + year + month + day);
  }

  var options = {
    onMove:   on_move,
    snap:     snap_to_day,
  };

  var tl = setupTimeline($('.visualization'), options);

  function before_submit (e) {
    var submit_data = _.mapObject( changed,
        function( val, key ) {
            return {
                column: val.column,
                current_id: val.current_id,
                from: val.start.getTime(),
                to:   (val.end || val.start).getTime()
            };
        }
    );
    $(window).off('beforeunload');

    // Store the data as JSON on the form
    var submit_json = JSON.stringify(submit_data);
    var data_field = $(hidden_input_sel);
    data_field.attr('value', submit_json );
  }

  // Set up form button behaviour
  $( save_elem_sel ).bind( 'click', before_submit );
  $( cancel_elem_sel ).bind( 'click', function (e) {
    $(window).off('beforeunload');
  });

  var layout_identifier = $('body').data('layout-identifier');

  function on_select (properties) {
    var items = properties.items;
    if (items.length == 0) {
        $('.bulk_href').on('click', function(e) {
            e.preventDefault();
            alert("Please select some records on the timeline first");
            return false;
        });
    } else {
        var hrefs = [];
        $("#delete_ids").empty();
        properties.items.forEach(function(item) {
            var id = item.replace(/\+.*/, '');
            hrefs.push("id=" + id);
            $("#delete_ids").append('<input type="hidden" name="delete_id" value="' + id + '">');
        });
        var href = hrefs.join('&');
        $('#update_href').attr("href", "/" + layout_identifier + "/bulk/update/?" + href);
        $('#clone_href').attr("href", "/" + layout_identifier + "/bulk/clone/?" + href);
        $('#count_delete').text(items.length);
        $('.bulk_href').off();
    }
  }

  tl.on('select', on_select);
  on_select({ items: [] });

  setupTippy();

  setupOtherUserViews();
}

export { DataTimelinePage };
