import 'components/button/lib/rename-button';
import 'util/filedrag';
import { upload } from 'util/upload/UploadControl';
import { validateCheckboxGroup } from 'validation';
import { formdataMapper } from 'util/mapper/formdataMapper';
import { logging } from 'logging';
import { RenameEvent } from 'components/button/lib/rename-button';
import { FileDropEvent } from 'util/filedrag';
import ErrorHandler from 'util/errorHandler';

/**
 * Interface for the file data returned from the server.
 */
interface FileData {
    /**
     * Identifier for the file.
     * @type {number | string}
     */
    id: number | string;
    /**
     * Name of the file.
     * @type {string}
     */
    filename: string;
}

/**
 * Interface for the response received after renaming a file.
 */
interface RenameResponse {
    /**
     * Identifier for the file.
     * @type {number | string}
     */
    id: number | string;
    /**
     * Name of the file after renaming.
     * @type {string}
     */
    name: string;
    /**
     * Indicates whether the operation was successful.
     * @type {boolean}
     */
    is_ok: boolean;
}

/**
 * DocumentComponent class for handling document upload functionality.
 */
class DocumentComponent {
    readonly type = 'document';
    readonly el: JQuery<HTMLElement>;
    readonly fileInput: JQuery<HTMLInputElement>;
    errors: (string|Error)[];
    handler: ErrorHandler;

    /**
     * Create a new DocumentComponent.
     * @param {JQuery<HTMLElement> | HTMLElement} el The HTML element for the document component, can be a jQuery object or a plain HTMLElement.
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.el.closest('.fieldset').find('.rename')
            .renameButton()
            .on('rename', async (ev: RenameEvent) => {
                if (!ev) throw new Error('e is not a RenameEvent - this shouldn\'t happen!');
                const $target = $(ev.target);
                await this.renameFile($target.data('field-id'), ev.oldName, ev.newName, $('body').data('csrf'));
            });
        this.fileInput = this.el.find<HTMLInputElement>('.form-control-file');
    }

    /**
     * Initialize the document component by setting up event listeners and drag-and-drop functionality.
     * @throws {Error} If the file upload element cannot be found.
     */
    async init() {
        const url = this.el.data('fileupload-url');

        const tokenField = this.el.closest('form').find('input[name="csrf_token"]');
        const csrf_token = tokenField.val() as string;
        const dropTarget = this.el.closest('.file-upload');

        const columnId = this.el.closest('.linkspace-field')?.data('column-id') ?? 0;
        this.handler = new ErrorHandler(this.el.find('.error-messages')[0]);

        if (dropTarget) {
            const dragOptions = { allowMultiple: true };
            dropTarget.filedrag(dragOptions).on('fileDrop', ({ file }: FileDropEvent) => {
                this.handler.clearErrors();
                logging.info('File dropped', file);
                this.handleAjaxUpload(url, csrf_token, file, columnId);
            });
        } else {
            throw new Error('Could not find file-upload element');
        }

        this.fileInput.on('change', (ev) => {
            if (!(ev.target instanceof HTMLInputElement)) {
                throw new Error('Could not find file-upload element');
            }

            const file = ev.target.files![0];
            if (!file || file === undefined || !file.name) return;
            const formData = formdataMapper({ file, csrf_token, column_id: columnId });
            upload<FileData>(url, formData, 'POST', (loaded, total) => this.showProgress(file.name, loaded, total)).then((data)=>{
                this.addFileToField({ id: data.id, name: data.filename });
            })
                .catch((e) => {
                    if(JSON.parse(e as string)?.message)
                        e = JSON.parse(e as string).message;
                    this.handler.addError(e);
                });
        });
    }

    /**
     * Show the progress of the file upload.
     * @param {string} file The name of the file being uploaded.
     * @param {number} loaded The number of bytes loaded so far.
     * @param {number} total The total number of bytes to be loaded.
     */
    showProgress(file: string, loaded: number, total: number) {
        let uploadProgression = Math.round((loaded / total) * 100);
        if (uploadProgression == Infinity) {
            // This will occur when there is an error uploading the file or the file is empty
            uploadProgression = 100;
        }
        let barContainer = this.el?.find('.progress-bar__container[data-file-name="' + file + '"] ');
        if (!barContainer || barContainer.length < 1) {
            this.createProgressBar(this.el, file);
            barContainer = this.el.find('.progress-bar__container[data-file-name="' + file + '"]');
        }
        barContainer.css('width', undefined);
        barContainer.find('.progress-bar__percentage').html(uploadProgression === 100 ? 'complete' : `${uploadProgression}%`);
        barContainer.find('.progress-bar__progress').css('width', `${uploadProgression}%`);
    }

    /**
     * Create a progress bar for the file upload.
     * @param el The element to attach the progress bar to.
     * @param file The name of the file for which the progress bar is being created.
     */
    createProgressBar(el: JQuery<HTMLElement>, file: string) {
        const progressBar = $(`
            <div class="progress-bar__container" data-file-name="${file}">
                <div class="progress-bar__progress">
                    <span class="progress-bar__percentage">0%</span>
                </div>
            </div>
        `);
        const barContainer = el?.find('.progress-bars');
        barContainer.append(progressBar);
        progressBar.show();
    }

    /**
     * Upload a file via AJAX.
     * @param {string} uri The URI to which the file will be uploaded.
     * @param {string} csrf_token The CSRF token for security.
     * @param {File} file The file to be uploaded.
     */
    handleAjaxUpload(uri: string, csrf_token: string, file: File, columnId: number) {
        try {
            if (!file) this.showException(new Error('No file provided'));

            const fileData = formdataMapper({ file, csrf_token, column_id: columnId });

            upload<FileData>(uri, fileData, 'POST', (loaded, total) => this.showProgress(file.name, loaded, total)).then((data) => {
                this.addFileToField({ id: data.id, name: data.filename });
            })
                .then(
                    () => {
                        $(this.el.find('.progress-bar__container[data-file-name="' + file.name + '"]'))
                            .hide();
                    }
                )
                .catch((e) => {
                    if(JSON.parse(e as string)?.message)
                        e = JSON.parse(e as string).message;
                    else if (typeof e == 'object' && 'message' in e)
                        e = e.message;
                    this.handler.addError(e);
                    $(this.el.find('.progress-bar__container[data-file-name="' + file.name + '"]'))
                        .hide();
                });
        } catch (e) {
            this.showException(e instanceof Error || 'message' in e ? e.message : e as string ?? e.toString());
        }
    }

    /**
     * Add a file to the field.
     * @param {object} file The file to be added to the field.
     * @param {number | string} file.id The ID of the file.
     * @param {string} file.name The name of the file.
     */
    addFileToField(file: { id: number | string; name: string }) {
        const $fieldset = this.el.closest('.fieldset');
        const $ul = $fieldset.find('.fileupload__files');
        const fileId = file.id;
        const fileName = file.name;
        const field = $fieldset.find('.input--file').data('field');
        const csrf_token = $('body').data('csrf');

        if (!this.el || !this.el.length || !this.el.closest('.linkspace-field').data('is-multivalue')) {
            $ul.empty();
        }

        const $li = $(`
            <li class="list__item">
                <div class="row">
                    <div class="col-auto align-content-center">
                        <input type="checkbox" id="file-${fileId}" name="${field}" value="${fileId}"
                            aria-label="${fileName}" data-filename="${fileName}" checked="">
                        <label for="file-${fileId}">Include File. Current file name:</label>
                        <a id="current-${fileId}" class="link link--plain"
                            href="/file/${fileId}">${fileName}</a>
                        <button data-field-id="${fileId}" class="rename btn btn-plain btn-small btn-sm py-0"
                            title="Rename file" type="button"></button>
                    </div>
                </div>
            </li>
        `);

        $ul.append($li);
        $ul.closest('.linkspace-field').trigger('change');
        validateCheckboxGroup($fieldset.find('.list'));
        $fieldset.find('input[type="file"]').removeAttr('required');
        const button = `.rename[data-field-id="${file.id}"]`;
        const $button = $(button);
        $button.renameButton().on('rename', async (ev: RenameEvent) => {
            await this.renameFile(fileId as number ?? parseInt(fileId.toString()), ev.oldName, ev.newName, csrf_token, true);
        });
    }

    /**
     * Rename a file.
     * @param {number} fileId The ID of the file to be renamed.
     * @param {string} oldName The current name of the file.
     * @param {string} newName The new name for the file.
     * @param {string} csrf_token The CSRF token for security.
     * @param {boolean} is_new Indicates if the file is new (default is false).
     */
    private async renameFile(fileId: number, oldName: string, newName: string, csrf_token: string, is_new: boolean = false) { // for some reason using the ev.target doesn't allow for changing of the data attribute - I don't know why, so I've used the button itself
        try {
            const filename = newName;
            const url = `/api/file/${fileId}`;
            const mappedData = formdataMapper({ csrf_token, filename, is_new: is_new ? 1 : 0 });
            const data = await upload<RenameResponse>(url, mappedData, 'PUT');
            if (is_new) {
                $(`#current-${fileId}`).text(data.name);
            } else {
                $(`#current-${fileId}`).closest('li')
                    .remove();
                const { id, name } = data;
                this.addFileToField({ id, name });
            }
        } catch (error) {
            let e=error;
            if(JSON.parse(error as string)?.message)
                e = JSON.parse(error as string).message;
            else if (typeof error == 'object' && 'message' in error)
                e = e.message;
            this.showException(e);
            const current = $(`#current-${fileId}`);
            current.text(oldName);
        }
    }

    /**
     * Show an exception message in the progress bar.
     * @param {string | Error} e The error to be displayed.
     */
    showException(e: string | Error) {
        this.handler.addError(e);
    }

    /**
     * Hide the exception message in the progress bar.
     */
    hideException() {
        this.el.find('.progress-bar__container')
            .css('width', undefined)
            .removeClass('progress-bar__container--fail')
            .hide();
    }
}

/**
 * Create a new document component
 * @param {JQuery<HTMLElement> | HTMLElement} el The element to attach the document component to
 * @returns {DocumentComponent} The initialized document component
 */
export default function documentComponent(el: JQuery<HTMLElement> | HTMLElement) {
    const component = new DocumentComponent(el);
    component.init();
    return component;
}
