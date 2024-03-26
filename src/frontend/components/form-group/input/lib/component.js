import { Component } from 'component'
import { initValidationOnField, validateCheckboxGroup } from 'validation'
import initDateField from 'components/datepicker/lib/helper'
import TypeaheadBuilder from 'util/typeahead'
import { stopPropagation, hideElement, showElement } from 'util/common'

class InputComponent extends Component {
    constructor(element)  {
      super(element)
      this.el = $(this.element)

      if (this.el.hasClass('input--password')) {
        this.btnReveal = this.el.find('.input__reveal-password')
        this.input = this.el.find('.form-control')
        this.initInputPassword()
      } else if (this.el.hasClass('input--logo')) {
        this.logoDisplay = this.el.parent().find('img');
        this.fileInput = this.el.find('.form-control-file')
        this.initInputLogo();
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

    initInputLogo() {
      if (this.logoDisplay.attr('src') == '#') this.logoDisplay.hide();

      this.el.find('.file').hide();

      this.fileInput.on('change', (ev) => {
        stopPropagation(ev);
        const url = this.el.data("fileupload-url")

        const formData = new FormData();
        formData.append('file', this.el.find('input[type="file"]')[0].files[0]);
        formData.append('csrf_token', $('body').data('csrf'));

        import(/* webpackChunkName: "uploader" */ 'util/upload')
          .then(({ upload }) => {
            upload(url, formData)
              .then((data) => {
                if (data && !data.error) {
                  const version = this.logoDisplay.attr('src').split('?')[1];
                  const newVersion = version ? parseInt(version) + 1 : 1;
                  this.logoDisplay.attr('src', data.url + '?' + newVersion);
                  this.logoDisplay.show();
                } else if (data.error) {
                  throw new Error(`Error: ${data.text}`);
                } else {
                  throw new Error(`Error: No data returned`);
                }
              }).catch((error) => {
                console.error(error);
              });
          });
      });
    }

    //TODO: Refactor this method to use the same method as the logo upload - blueimp-file-upload needs to be removed
    initInputDocument() {
      const url = this.el.data("fileupload-url")
      const $progressBarContainer = this.el.find(".progress-bar__container")
      const $progressBarProgress = this.el.find(".progress-bar__progress")
      const $progressBarPercentage = this.el.find(".progress-bar__percentage")
      const self = this

      const tokenField = this.el.closest('form').find('input[name="csrf_token"]');
      const token = tokenField.val();
      const dropTarget = this.el.closest('.file-upload');
      if (dropTarget) {
        const dragOptions = { allowMultiple: false };
        dropTarget.filedrag(dragOptions).on('onFileDrop', (ev, file) => {
          $progressBarContainer.css("display", "block");
          $progressBarPercentage.html("0%");
          $progressBarProgress.css("width", "0%");
          $progressBarContainer.removeClass('progress-bar__container--fail');
          const progress = (size, total) => {
            const percentage = Math.round((size / total) * 10000) / 100 + "%";
            $progressBarPercentage.html(percentage);
            $progressBarProgress.css("width", percentage);
          };
          this.handleAjaxUpload(url, token, file, progress);
        });
        this.error = dropTarget.parent().find('.upload__error');
      } else throw new Error("Could not find file-upload element");

      this.el.on("change", () => {
        import(/* webpackChunkName: "uploader" */ 'util/upload')
          .then(({ upload }) => {
            const formData = new FormData();
            formData.append('csrf_token', token);
            formData.append('file', this.el.find('input[type="file"]')[0].files[0]);

            $progressBarContainer.css("display", "block");
            $progressBarPercentage.html("0%");
            $progressBarProgress.css("width", "0%");
            $progressBarContainer.removeClass('progress-bar__container--fail');

            upload(url, formData, "POST", (size, total) => {
              const percentage = Math.round((size / total) * 10000) / 100 + "%";
              $progressBarPercentage.html(percentage);
              $progressBarProgress.css("width", percentage);
            }).then((data) => {
              if (data && !data.error) {
                self.addFileToField({ id: data.id, name: data.filename });
              } else if (data.error) {
                throw new Error(`Error: ${data.text}`);
              } else {
                throw new Error(`Error: No data returned`);
              }
            }).catch((error) => {
              $progressBarProgress.css("width", "100%");
              $progressBarContainer.addClass('progress-bar__container--fail');
              if (error) {
                $progressBarPercentage.html("Error: " + error);
              } else {
                $progressBarPercentage.html("An unexpected error occurred");
              }
              console.log(error);
            });
          });
      });
    }

    initInputAutocomplete() {
      const self = this

      const suggestionCallback = (suggestion) => {
        $(self.el).find('input[type="hidden"]').val(suggestion.id)
      }

      const builder = new TypeaheadBuilder();
      builder
        .withInput($(self.input))
        .withCallback(suggestionCallback)
        .withAjaxSource(self.getURL())
        .withName('users')
        .build()
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
      initDateField(this.input)
    }

    initInputPassword() {
      if (!this.btnReveal) {
        return
      }

      this.btnReveal.removeClass("show")
      this.btnReveal.click( (ev) => { this.handleClickReveal(ev) } )
    }

    handleAjaxUpload(uri, csrf_token, file, progressCallback = undefined) {
      try {
        hideElement(this.error);
        if (!file) throw new Error("No file provided");
        const self = this;

        const fileData = new FormData();
        fileData.append("file", file);
        fileData.append("csrf_token", csrf_token);

        import(/* webpackChunkName: "uploader" */ 'util/upload')
          .then(({ upload }) => {
            upload(uri, fileData, "POST", progressCallback).then((data) => {
              if (data && !data.error) {
                self.addFileToField({ id: data.id, name: data.filename });
              } else if (data.error) {
                throw new Error(`Error: ${data.text}`);
              } else {
                throw new Error(`Error: No data returned`);
              }
            }).catch((error) => {
              console.error(error);
            });
          });
      } catch (e) {
        this.showException(e);
      }
    }

    showException(e) {
        this.error.html(e);
        showElement(this.error);
    }

    handleFormUpload(file) {
        if (!file) throw new Error("No file provided");
        const form = this.el.closest('form');
        const action = form.attr('action') ? window.location.href + form.attr('action') : window.location.href;
        const method = form.attr('method') || 'GET';
        const tokenField = form.find('input[name="csrf_token"]');
        const token = tokenField.val();
        const formData = new FormData();
        formData.append('file', file);
        if (method.toUpperCase() == 'POST') {
          import(/* webpackChunkName: "uploader" */ 'util/upload')
            .then(({ upload }) => {
              formData.append('file', file);
              formData.append('csrf_token', token);
              upload(action, formDatam, method.toUpperCase());
            }).catch((error) => {
              console.error(error);
            });
        } else {
            throw new Error("Method not supported");
        }
    }

    initInputFile() {
        const dropTarget = this.el.closest('.file-upload');
        if (dropTarget) {
            const dragOptions = { allowMultiple: false };
            dropTarget.filedrag(dragOptions).on('onFileDrop', (ev, file) => {
                this.handleFormUpload(file);
            });
        } else throw new Error("Could not find file-upload element");

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

    addFileToField(file) {
      const $fieldset = this.el.closest('.fieldset');
      const $ul = $fieldset.find(".fileupload__files")
      const $field = this.el
      const fileId = file.id
      const fileName = file.name
      const field = $fieldset.find('.input--file').data("field")
      if (!this.el.data("multivalue")) {
        $ul.empty();
      }
      const $li = $(
        `<li class="help-block">
          <div class="checkbox">
            <input type="checkbox" id="file-${fileId}" name="${field}" value="${fileId}" aria-label="${fileName}" data-filename="${fileName}" checked>
            <label for="file-${fileId}">
              <span>Include file. Current file name: <a class="link" href="/file/${fileId}">${fileName}</a>.</span>
            </label>
          </div>
        </li>`
      );
      $ul.append($li);
      // Change event will alreayd have been triggered with initial file
      // selection (XXX ideally remove this first trigger?). Trigger
      // change again now that the full element has been recreated.
      $ul.closest('.linkspace-field').trigger('change')
      // .list class contains the checkboxes to be validated
      validateCheckboxGroup($fieldset.find('.list'))
      // Once a file has been uploaded, it will appear as a checkbox and
      // the file input will still be empty. Remove the HTML required
      // attribute so that the form can be submitted
      $fieldset.find('input[type="file"]').removeAttr('required');
    }

}

export default InputComponent
