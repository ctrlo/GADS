const setupDatePicker = (() => {
  const setupDatePickers = context => {
    $(".datepicker", context).datepicker({
      format: $(document.body).data("config-dataformat-datepicker"),
      autoclose: true
    });
  };

  const setupDateRange = context => {
    $(".input-daterange input.from", context).each(function() {
      $(this).on("changeDate", function() {
        var toDatepicker = $(this)
          .parents(".input-daterange")
          .find(".datepicker.to");
        if (!toDatepicker.val()) {
          toDatepicker.datepicker("update", $(this).datepicker("getDate"));
        }
      });
    });
  };

  const setupRemoveDatePicker = context => {
    $(document, context).on("click", ".remove_datepicker", function() {
      var dp = ".datepicker" + $(this).data("field");
      $(dp).datepicker("destroy");
      //eslint-disable-next-line no-alert
      alert("Date selector has been disabled for this field");
    });
  };

  return context => {
    setupDatePickers(context);
    setupDateRange(context);
    setupRemoveDatePicker(context);
  };
})();

export { setupDatePicker };
