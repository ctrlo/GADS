import { Component } from 'component'
import 'summernote/dist/summernote-bs4'
import { logging } from 'logging'

/**
 * Summernote component for rich text editing.
 */
class SummerNoteComponent extends Component {
  /**
   * Create a new summernote component
   * @param {HTMLElement} element The element to attach the summernote component to
   */
  constructor(element) {
    super(element)
    this.initSummerNote()
  }

  /**
   * Initialize the summernote component
   */
  initSummerNote() {
    const self = this;
    $(this.element).summernote({
      toolbar: [
        ['style', ['style']],
        ['font', ['bold', 'underline', 'clear']],
        ['fontname', ['fontname']],
        ['color', ['color']],
        ['para', ['ul', 'ol', 'paragraph']],
        ['table', ['table']],
        ['insert', ['link', 'picture', 'video']],
        ['view', ['codeview', 'help']],
      ],
      dialogsInBody: true,
      height: 400,
      callbacks: {
        // Load initial content
        onInit: function () {
          const $sum_div = $(this);
          const $sum_input = $sum_div.siblings('input[type=hidden].summernote_content')
          $(this).summernote('code', $sum_input.val())
        },
        onImageUpload: function (files) {
          for (let i = 0; i < files.length; i++) {
            self.handleHtmlEditorFileUpload(files[i], this)
          }
        },
        onChange: function (contents) {
          const $sum_div = $(this).closest('.summernote')
          // Ensure submitted content is empty string if blank content
          // (easier checking for blank values)
          if ($sum_div.summernote('isEmpty')) {
            contents = ''
          }
          const $sum_input = $sum_div.siblings('input[type=hidden].summernote_content');
          $sum_input.val(contents)
        }
      }
    })
  }

  /**
   * Handle upload within the HTML editor
   * @param {*} file The file to upload
   * @param {*} el The element object
   */
  handleHtmlEditorFileUpload(file, el) {
    if (file.type.includes('image')) {
      const data = new FormData()
      data.append('file', file)
      data.append('csrf_token', $('body').data('csrf'))
      $.ajax({
        url: '/file?ajax&is_independent',
        type: 'POST',
        contentType: false,
        cache: false,
        processData: false,
        dataType: 'JSON',
        data: data,
        success: function (response) {
          if (response.is_ok) {
            $(el).summernote('editor.insertImage', response.url)
          } else {
            logging.error(response.error)
          }
        }
      }).fail(function (e) {
        logging.error(e)
      })
    } else {
      logging.error('The type of file uploaded was not an image')
    }
  }
}

export default SummerNoteComponent
