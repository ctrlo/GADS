const setupSubmitListener = (() => {
  var setupSubmitListener = function(context) {
    $('.edit-form', context).on('submit', function(e) {
        var $button = $(document.activeElement);
        $button.prop('disabled', true);
        if ($button.prop("name")) {
            $button.after('<input type="hidden" name="' + $button.prop("name") + '" value="' + $button.val() + '" />');
        }
    });
  }

  return context => {
    setupSubmitListener(context);
  };
})()

export { setupSubmitListener };
