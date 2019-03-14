$(function() {
  $('.remember-me').each(function() {
    var $widget = $(this);
    var $checkbox = $widget.find('input:checkbox');

    $checkbox.on('change', updateDisplay);

    function updateDisplay() {
      var isChecked = $checkbox.is(':checked');
      $checkbox.toggleClass("remember--checked", isChecked);
    }
  });
});
