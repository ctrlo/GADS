const setupAccessibility = (() => {
  var setupAccessibility = function(context) {
    $("a[role=button]", context).on("keypress", function(e) {
      if (e.keyCode === 32) {
        // SPACE
        this.click();
      }
    });

    var $navbar = $(".navbar-fixed-bottom", context);
    if ($navbar.length) {
      $(".edit-form .form-group", context).on("focusin", function(e) {
        var $el = $(e.target);
        var elTop = $el.offset().top;
        var elBottom = elTop + $el.outerHeight();
        var navbarTop = $navbar.offset().top;
        if (elBottom > navbarTop) {
          $("html, body").animate(
            {
              scrollTop: $(window).scrollTop() + elBottom - navbarTop + 20
            },
            300
          );
        }
      });
    }
  };

  return context => {
    setupAccessibility(context);
  };
})();

export { setupAccessibility };
