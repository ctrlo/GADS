const LoginPage = () => {
  $(".remember-me").each(function() {
    var $widget = $(this);
    var $checkbox = $widget.find("input:checkbox");

    $checkbox.on("change", updateDisplay);

    /**
     *
     */
    function updateDisplay() {
      var isChecked = $checkbox.is(":checked");
      $checkbox.toggleClass("remember--checked", isChecked);
    }
  });

  $(".show-password").each(function() {
    var $widget = $(this);
    var $checkbox = $widget.find("input:checkbox");
    var passwordEl = document.querySelector("input[name=password]");

    $checkbox.on("change", updateDisplay2);

    /**
     *
     */
    function updateDisplay2() {
      var isChecked = $checkbox.is(":checked");
      $checkbox.toggleClass("show_password--checked", isChecked);
      passwordEl.type = isChecked ? "text" : "password";
    }
  });
};

export { LoginPage };
