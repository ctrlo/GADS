const setupFileUpload = (() => {
  var setupFileUpload = function (context) {
    var $nodes = $('.fileupload', context);
    $nodes.each(function () {
        var $el = $(this);
        var $ul = $el.find("ul");
        var url = $el.data("fileupload-url");
        var field = $el.data("field");
        var $progressBarContainer = $el.find('.progress-bar__container');
        var $progressBarProgress = $el.find('.progress-bar__progress');
        var $progressBarPercentage = $el.find('.progress-bar__percentage')

        $el.fileupload({
            dataType: 'json',
            url: url,
            paramName: "file",

            submit: function (e, data) {
                $progressBarContainer.css('display', 'block');
                $progressBarPercentage.html("0%");
                $progressBarProgress.css('width', '0%');
            },
            progress: function (e,data) {
                if (!$el.data("multivalue")) {
                    var $uploadProgression = Math.round(data.loaded / data.total * 10000)/100 + '%';
                    $progressBarPercentage.html($uploadProgression);
                    $progressBarProgress.css('width', $uploadProgression);
                }
            },
            progressall: function (e, data) {
                if ($el.data("multivalue")) {
                    var $uploadProgression = Math.round(data.loaded / data.total * 10000)/100 + '%';
                    $progressBarPercentage.html($uploadProgression);
                    $progressBarProgress.css('width', $uploadProgression);
                }

            },
            done: function (e, data) {
                if (!$el.data("multivalue")) {
                    $ul.empty();
                }
                var fileId = data.result.url.split("/").pop();
                var fileName = data.files[0].name;

                var $li = $('<li class="help-block"><input type="checkbox" name="' + field + '" value="' + fileId + '" aria-label="' + fileName + '" checked>Include file. Current file name: <a href="/file/' + fileId + '">' + fileName + '</a>.</li>');
                $ul.append($li);
            }
        });
    });
  };

  return context => {
    setupFileUpload(context);
  };
})()

export { setupFileUpload };

