import { formdataMapper } from 'util/mapper/formdataMapper';
import { upload } from 'util/upload/UploadControl';

/**
 * FileComponent class for handling file upload functionality.
 */
class FileComponent {
    el: JQuery<HTMLElement>;
    fileInput: JQuery<HTMLInputElement>;
    fileName: JQuery<HTMLElement>;
    fileDelete: JQuery<HTMLElement>;
    inputFileLabel: JQuery<HTMLElement>;

    protected readonly type = 'file';

    /**
     * Create a new FileComponent.
     * @param {HTMLElement | JQuery<HTMLElement>} el The HTML element for the file component, can be a jQuery object or a plain HTMLElement.
     */
    constructor(el: HTMLElement | JQuery<HTMLElement>) {
        this.el = el instanceof HTMLElement ? $(el) : el;
        this.fileInput = this.el.find('.form-control-file') as JQuery<HTMLInputElement>;
        this.fileName = this.el.find('.file__name');
        this.fileDelete = this.el.find('.file__delete');
        this.inputFileLabel = this.el.find('.input__file-label');
    }

    /**
     * Initialize the file component by setting up event listeners and drag-and-drop functionality.
     */
    init() {
        const dropTarget = this.el.closest('.file-upload');
        if (dropTarget) {
            const dragOptions = { allowMultiple: false };
            (dropTarget as any).filedrag(dragOptions).on('onFileDrop', (ev, file) => {
                this.handleFormUpload(file);
            });
        } else {
            throw new Error('Could not find file-upload element');
        }

        this.fileInput.on('change', this.changeFile);
        this.inputFileLabel.on('keyup', this.uploadFile);
        this.fileDelete.addClass('hidden');
        this.fileDelete.on('click', this.deleteFile);
    }

    /**
     * Handle the file upload process.
     * @param {File} file The file to be uploaded.
     */
    handleFormUpload = (file: File) => {
        // As some of these, if not all, are event handlers, scoping can get a bit wiggy; using arrow functions to keep the scope of `this` to the class
        if (!file) throw new Error('No file provided');

        const form = this.el.closest('form');
        const action = form.attr('action') ? window.location.href + form.attr('action') : window.location.href;
        const method = (form.attr('method') || 'GET').toUpperCase();
        const tokenField = form.find('input[name="csrf_token"]');
        const csrf_token = tokenField.val() as string ?? tokenField.val()?.toString();
        const formData = formdataMapper({ file, csrf_token });

        if (method === 'POST') {
            upload(action, formData, 'POST').catch(console.error);
        } else {
            throw new Error('Method not supported');
        }
    };

    /**
     * Handle the change event when a file is selected.
     * @param {JQuery.ChangeEvent<HTMLInputElement>} ev The change event triggered when a file is selected.
     */
    changeFile = (ev: JQuery.ChangeEvent<HTMLInputElement>) => {
        const [file] = ev.target.files!;
        const { name: fileName } = file;

        this.fileName.text(fileName);
        this.fileName.attr('title', fileName);
        this.fileDelete.removeClass('hidden');
    };

    /**
     * Upload the file when the input file label is focused and the space or enter key is pressed.
     * @param {JQuery.KeyUpEvent} ev The keyup event triggered when the input file label is focused.
     */
    uploadFile = (ev: JQuery.KeyUpEvent) => {
        if (ev.which === 32 || ev.which === 13) {
            this.fileInput.trigger('click');
        }
    };

    /**
     * Delete the selected file and reset the file input and display.
     * @todo set focus back to input__file-label without triggering keyup event on it
     */
    deleteFile = () => {
        this.fileName.text('No file chosen');
        this.fileName.attr('title', '');
        this.fileInput.val('');
        this.fileDelete.addClass('hidden');
    };
}

/**
 * Create a new FileComponent instance and initialize it.
 * @param {HTMLElement | JQuery<HTMLElement>} el The HTML element for the file component, can be a jQuery object or a plain HTMLElement.
 */
export default function fileComponent(el: HTMLElement | JQuery<HTMLElement>) {
    const component = new FileComponent(el);
    component.init();
}
