import { Component } from 'component'
import { initValidationOnField, validateCheckboxGroup } from 'validation'
import  'bootstrap-datepicker'
import 'jquery-typeahead'
import 'blueimp-file-upload'

class InputComponent extends Component {
    constructor(element)  {
      super(element)
      this.el = $(this.element)

      if (this.el.hasClass('input--password')) {
        this.btnReveal = this.el.find('.input__reveal-password')
        this.input = this.el.find('.form-control')
        this.initInputPassword()
      } else if (this.el.hasClass('input--document')) {
        this.fileInput = this.el.find('.form-control-file')
        this.initInputDocument()
      } else if (this.el.hasClass('input--file')) {
        this.fileInput = this.el.find('.form-control-file')
        this.fileName = this.el.find('.file__name')
        this.fileDelete = this.el.find('.file__delete')
        this.inputFileLabel = this.el.find('.input__file-label')
        this.initInputFile()
      } else if (this.el.hasClass('input--datepicker')) {
        this.input = this.el.find('.form-control')
        this.initInputDate()
      } else if (this.el.hasClass('input--autocomplete')) {
        this.input = this.el.find('.form-control')
        this.initInputAutocomplete()
      } 

      if (this.el.hasClass("input--required")) {
        initValidationOnField(this.el)
      }
    }

    initInputDocument() {
      const url = this.el.data("fileupload-url")
      const field = this.el.data("field")
      const $fieldset = this.el.closest('.fieldset');
      const $ul = $fieldset.find(".fileupload__files")
      const $progressBarContainer = this.el.find(".progress-bar__container")
      const $progressBarProgress = this.el.find(".progress-bar__progress")
      const $progressBarPercentage = this.el.find(".progress-bar__percentage")
      const self = this

      this.el.fileupload({
        dataType: "json",
        url: url,
        paramName: "file",

        submit: function() {
          $progressBarContainer.css("display", "block");
          $progressBarPercentage.html("0%");
          $progressBarProgress.css("width", "0%");
          $progressBarContainer.removeClass('progress-bar__container--fail');
        },
        progress: function(e, data) {
          if (!self.el.data("multivalue")) {
            var $uploadProgression =
              Math.round((data.loaded / data.total) * 10000) / 100 + "%";
            $progressBarPercentage.html($uploadProgression);
            $progressBarProgress.css("width", $uploadProgression);
          }
        },
        progressall: function(e, data) {
          if (self.el.data("multivalue")) {
            var $uploadProgression =
              Math.round((data.loaded / data.total) * 10000) / 100 + "%";
            $progressBarPercentage.html($uploadProgression);
            $progressBarProgress.css("width", $uploadProgression);
          }
        },
        done: function(e, data) {
          if (!self.el.data("multivalue")) {
            $ul.empty();
          }
          var fileId = data.result.url.split("/").pop();
          var fileName = data.files[0].name;

          var $li = $(
            `<li class="help-block">
              <div class="checkbox">
                <input type="checkbox" id="file-${fileId}" name="${field}" value="${fileId}" aria-label="${fileName}" checked>
                <label for="file-${fileId}">
                  <span>Include file. Current file name: <a class="link" href="/file/${fileId}">${fileName}</a>.</span>
                </label>
              </div>
            </li>`
          );
          $ul.append($li);
          // .list class contains the checkboxes to be validated
          validateCheckboxGroup($fieldset.find('.list'))
          // Once a file has been uploaded, it will appear as a checkbox and
          // the file input will still be empty. Remove the HTML required
          // attribute so that the form can be submitted
          $fieldset.find('input[type="file"]').removeAttr('required');
        },
        fail: function(e, data) {
          const ret = data.jqXHR.responseJSON;
          $progressBarProgress.css("width", "100%");
          $progressBarContainer.addClass('progress-bar__container--fail');
          if (ret.message) {
              $progressBarPercentage.html("Error: " + ret.message);
          } else {
              $progressBarPercentage.html("An unexpected error occurred");
          }
        }
      });
    }

    initInputAutocomplete() {
      const self = this
      $(self.input).typeahead({
        minLength: 2,
        delay: 500,
        dynamic: true,
        order: 'asc',
        source: {
          name: {
            display: 'name',
            ajax: {
              type: 'GET',
              url: self.getURL(),
              dataType: 'json'
            }
          }
        },
        callback: {
          onClickAfter (node, a, item, event) {
            $(self.el).find('input[type="hidden"]').val(item.id)
          }
        }
      })
    }

    getURL() {
      const devEndpoint = window.siteConfig && window.siteConfig.urls.autocompleteApi
      const layout_identifier = $('body').data('layout-identifier')

      if (devEndpoint) {
        return devEndpoint
      } else {
        return layout_identifier ? '/' + layout_identifier + '/match/user/' : '/match/user/'
      }
    }

    initInputDate() {
      this.input.datepicker({
        "format": "yyyy-mm-dd",
        "autoclose": "true"
      }).on('show.bs.modal', function(event) {
        // prevent datepicker from firing bootstrap modal "show.bs.modal"
        event.stopPropagation()
      }).on('hide', (e) => {
        // prevent datepicker from firing bootstrap modal "hide.bs.modal"
        e.stopPropagation()
      })
    }

    initInputPassword() {
      if (!this.btnReveal) {
        return
      }

      this.btnReveal.removeClass("show")
      this.btnReveal.click( (ev) => { this.handleClickReveal(ev) } )
    }

    initInputFile() {
      this.fileInput.change( (ev) => { this.changeFile(ev) } )
      this.inputFileLabel.bind( 'keyup', (ev) => { this.uploadFile(ev)} )

      this.fileDelete.addClass("hidden");
      this.fileDelete.click( (ev) => { this.deleteFile(ev) } )
    }

    handleClickReveal(ev) {
        const target = $(ev.target)

        this.btnReveal.toggleClass("show");

        if (this.input.attr("type") == "password") {
          this.input.attr("type", "text");
        } else {
          this.input.attr("type", "password");
        }
    }

    uploadFile(ev) {
      if ((ev.which === 32 || ev.which === 13)) {
        $('.form-control-file').click()
      }
    }

    changeFile(ev) {
      const [file] = ev.target.files
      const { name: fileName } = file

      this.fileName.text(`${fileName}`)
      this.fileName.attr('title', `${fileName}`)
      this.fileDelete.removeClass("hidden")
    }

    deleteFile() {
      this.fileName.text("No file chosen")
      this.fileName.attr('title', '')
      this.fileInput[0].value = '';
      this.fileDelete.addClass("hidden");
      // TO DO: set fo us back to input__file-label 9without triggering keyup event on it)
    }
}

export default InputComponent
