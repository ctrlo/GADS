import { setupFontAwesome } from "./font-awesome";

const setupCalendar = (() => {
  const initCalendar = context => {
    var calendarEl = $("#calendar", context);
    if (!calendarEl.length) return false;

    var options = {
      events_source: `/${calendarEl.attr(
        "data-event-source"
      )}/data_calendar/${new Date().getTime()}`,
      view: calendarEl.data("view"),
      tmpl_path: "/tmpls/",
      tmpl_cache: false,
      onAfterEventsLoad: function(events) {
        if (!events) {
          return;
        }
        var list = $("#eventlist");
        list.html("");

        $.each(events, function(key, val) {
          $(document.createElement("li"))
            .html(`<a href="${val.url}">${val.title}</a>`)
            .appendTo(list);
        });
      },
      onAfterViewLoad: function(view) {
        $("#caltitle").text(this.getTitle());
        $(".btn-group button").removeClass("active");
        $(`button[data-calendar-view="${view}"]`).addClass("active");
      },
      classes: {
        months: {
          general: "label"
        }
      }
    };

    const day = calendarEl.data("calendar-day-ymd");
    if (day) {
      options.day = day;
    }

    return calendarEl.calendar(options);
  };

  const setupButtons = (calendar, context) => {
    $(".btn-group button[data-calendar-nav]", context).each(function() {
      var $this = $(this);
      $this.click(function() {
        calendar.navigate($this.data("calendar-nav"));
      });
    });

    $(".btn-group button[data-calendar-view]", context).each(function() {
      var $this = $(this);
      $this.click(function() {
        calendar.view($this.data("calendar-view"));
      });
    });
  };

  const setupSpecifics = (calendar, context) => {
    $("#first_day", context).change(function() {
      var value = $(this).val();
      value = value.length ? parseInt(value) : null;
      calendar.setOptions({ first_day: value });
      calendar.view();
    });

    $("#language", context).change(function() {
      calendar.setLanguage($(this).val());
      calendar.view();
    });

    $("#events-in-modal", context).change(function() {
      var val = $(this).is(":checked") ? $(this).val() : null;
      calendar.setOptions({ modal: val });
    });
    $("#events-modal .modal-header, #events-modal .modal-footer", context).click(
      function() {}
    );
  };

  return context => {
    const calendar = initCalendar(context);
    if (calendar) {
      setupButtons(calendar, context);
      setupSpecifics(calendar, context);
      setupFontAwesome();
    }
  };
})()

export { setupCalendar };
