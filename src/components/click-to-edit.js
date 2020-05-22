const setupClickToEdit = (() => {
  var confirmOnPageExit = function (e)
  {
      e = e || window.event;
      var message = 'Please note that any changes will be lost.';
      if (e)
      {
          e.returnValue = message;
      }
      return message;
  };

  var setupClickToEdit = function(context) {
      $('.click-to-edit', context).on('click', function() {
          var $editToggleButton = $(this);
          this.innerHTML = this.innerHTML === "Edit" ? "View" : "Edit";
          $($editToggleButton.data('viewEl')).toggleClass('expanded');
          $($editToggleButton.data('editEl')).toggleClass('expanded');

          if (this.innerHTML === "View") { // If button is showing view then we are on edit page
              window.onbeforeunload = confirmOnPageExit;
          } else {
              window.onbeforeunload = null;
          }
      });
      $(".submit_button").click( function() {
          window.onbeforeunload = null;
      });
      $(".remove-unload-handler").click( function() {
          window.onbeforeunload = null;
      });
  }

  return context => {
    setupClickToEdit(context);
  };
})()

export { setupClickToEdit };
