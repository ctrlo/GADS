const setupHtmlEditor = (() => {
  var handleHtmlEditorFileUpload = function(file, el) {
    if(file.type.includes('image')) {
        var data = new FormData();
        data.append('file', file);
        data.append('csrf_token', $('body').data('csrf-token'));
        $.ajax({
            url: '/file?ajax&is_independent',
            type: 'POST',
            contentType: false,
            cache: false,
            processData: false,
            dataType: 'JSON',
            data: data,
            success: function (response) {
                if(response.is_ok) {
                    $(el).summernote('editor.insertImage', response.url);
                } else {
                    console.log(response.error);
                }
            }
        })
        .fail(function(e) {
            console.log(e);
        });
    } else {
        console.log("The type of file uploaded was not an image");
    }
  }

  var setupHtmlEditor = function (context) {

    // Legacy editor - may be needed for IE8 support in the future
    /*
    tinymce.init({
        selector: "textarea",
        width : "800",
        height : "400",
        plugins : "table",
        theme_advanced_buttons1 : "bold, italic, underline, strikethrough, justifyleft, justifycenter, justifyright, bullist, numlist, outdent, i
        theme_advanced_buttons2 : "tablecontrols",
        theme_advanced_buttons3 : ""
    });
    */
    if (!$.summernote) {
        return;
    }

    $('.summernote', context).summernote({
        dialogsInBody: true,
        height: 400,
        callbacks: {
            // Load initial content
            onInit: function() {
                var $sum_div = $(this);
                var $sum_input = $sum_div.siblings('input[type=hidden].summernote_content');
                $(this).summernote('code', $sum_input.val());
            },
            onImageUpload: function(files) {
                for(var i = 0; i < files.length; i++) {
                    handleHtmlEditorFileUpload(files[i], this);
                }
            },
            onChange: function (contents, $editable) {
                var $sum_div = $(this).closest('.summernote');
                // Ensure submitted content is empty string if blank content
                // (easier checking for blank values)
                if ($sum_div.summernote('isEmpty')) {
                    contents = '';
                }
                var $sum_input = $sum_div.siblings('input[type=hidden].summernote_content');
                $sum_input.val(contents);
            },
        }
    });

    // Only setup global logic on initial setup
    if (context !== undefined) {
        return;
    }
  };


  return context => {
    setupHtmlEditor(context);
  };
})()

export { setupHtmlEditor };
