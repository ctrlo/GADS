import 'util/filedrag';
import { formdataMapper } from 'util/mapper/formdataMapper';
import { upload } from 'util/upload/UploadControl';

/**
 * File component
 */
class FileComponent {
    el: JQuery<HTMLElement>;
    fileInput: JQuery<HTMLInputElement>;
    fileName: JQuery<HTMLElement>;
    fileDelete: JQuery<HTMLElement>;
    inputFileLabel: JQuery<HTMLElement>;

    protected readonly type = 'file';

    /**
     * Create a new file component
     * @param el The element to attach the file component to
     */
    constructor(el: HTMLElement | JQuery<HTMLElement>) {
        this.el = el instanceof HTMLElement ? $(el) : el;
        this.fileInput = this.el.find('.form-control-file') as JQuery<HTMLInputElement>;
        this.fileName = this.el.find('.file__name');
        this.fileDelete = this.el.find('.file__delete');
        this.inputFileLabel = this.el.find('.input__file-label');
    }

    /**
     * Initialize the file component
     */
    init() {
        const dropTarget = this.el.closest('.file-upload');
        if (dropTarget) {
            const dragOptions = { allowMultiple: false };
            dropTarget.filedrag(dragOptions).on('onFileDrop', (ev, file) => {
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
     * Handle a file upload
     * @param file The file to upload
     */
    handleFormUpload = (file: File) => {
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
     * Handle the change event for the file input
     * @param ev The change event
     */
    changeFile = (ev: JQuery.ChangeEvent<HTMLInputElement>) => {
        const [file] = ev.target.files!;
        const { name: fileName } = file;

        this.fileName.text(fileName);
        this.fileName.attr('title', fileName);
        this.fileDelete.removeClass('hidden');
    };

    /**
     * Handle the enter or space key event for the input file label
     * @param ev The key event for the input file label
     */
    uploadFile = (ev: JQuery.KeyUpEvent) => {
        if (ev.which === 32 || ev.which === 13) {
            this.fileInput.trigger('click');
        }
    };

    /**
     * Delete the file
     */
    deleteFile = () => {
        this.fileName.text('No file chosen');
        this.fileName.attr('title', '');
        this.fileInput.val('');
        this.fileDelete.addClass('hidden');
        // TO DO: set focus back to input__file-label without triggering keyup event on it
    };
}

/**
 * Create a new file component
 * @param el The element to attach the file component to
 */
export default function fileComponent(el: HTMLElement | JQuery<HTMLElement>) {
    const component = new FileComponent(el);
    component.init();
}
