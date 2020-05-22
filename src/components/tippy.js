const setupTippy = (() => {
  var setupTippy = function (context) {
    var tippyContext = context || document;
    tippy(tippyContext.querySelectorAll('.vis-foreground'), {
        target: '.timeline-tippy',
        theme: 'light',
        onShown: function (e) {
            $('.moreinfo', context).off("click").on("click", function(e){
                var target = $( e.target );
                var record_id = target.data('record-id');
                var m = $("#readmore_modal");
                m.find('.modal-body').text('Loading...');
                m.find('.modal-body').load('/record_body/' + record_id);
                m.modal();
             });
        }
    });
  };

  return context => {
    setupTippy(context);
  };
})()

export { setupTippy };
