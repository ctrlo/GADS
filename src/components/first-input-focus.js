const setupFirstInputFocus = (() => {
  var setupFirstInputFocus = function(context) {
    $(".edit-form *:input[type!=hidden]:first", context).focus();
  };

  return context => {
    setupFirstInputFocus(context);
  };
})();

export { setupFirstInputFocus };
