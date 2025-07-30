import 'components/button/lib/rename-button';
import 'util/filedrag';
import { upload } from 'util/upload/UploadControl';
import { validateCheckboxGroup } from 'validation';
import { formdataMapper } from 'util/mapper/formdataMapper';
import { logging } from 'logging';
import { RenameEvent } from 'components/button/lib/rename-button';
import { fromJson } from 'util/common';
import { FileDropEvent } from 'util/filedrag';
import ErrorHandler from 'util/errorHandler';
import { isString } from 'util/typechecks';

interface FileData {
    id: number | string;
    filename: string;
}

interface RenameResponse {
    id: number | string;
    name: string;
    is_ok: boolean;
}

class DocumentComponent {
    readonly type = 'document';
    readonly el: JQuery<HTMLElement>;
    readonly fileInput: JQuery<HTMLInputElement>;
    errors: (string|Error)[];
    handler: ErrorHandler;

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.el.closest('.fieldset').find('.rename').renameButton().on('rename', async (ev: RenameEvent) => {
            if (!ev) throw new Error("e is not a RenameEvent - this shouldn't happen!")
            const $target = $(ev.target);
            await this.renameFile($target.data('field-id'), ev.oldName, ev.newName, $('body').data('csrf'));
        });
        this.fileInput = this.el.find<HTMLInputElement>('.form-control-file');
    }

    init() {
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
            }).catch((e) => {
                if(JSON.parse(e as string)?.message)
                    e = JSON.parse(e as string).message;
                this.handler.addError(e);
            });
        });
    }

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
        barContainer.css('width', undefined)
        barContainer.find('.progress-bar__percentage').html(uploadProgression === 100 ? 'complete' : `${uploadProgression}%`);
        barContainer.find('.progress-bar__progress').css('width', `${uploadProgression}%`);
    }

    createProgressBar(el: JQuery<HTMLElement>, file: string) {
        const progressBar = $(`
            <div class="progress-bar__container" data-file-name="${file}">
                <div class="progress-bar__progress">
                    <span class="progress-bar__percentage">0%</span>
                </div>
            </div>
        `);
        const barContainer = el?.find(".progress-bars");
        barContainer.append(progressBar);
        progressBar.show();
    }

    handleAjaxUpload(uri: string, csrf_token: string, file: File, columnId: number) {
        try {
            if (!file) this.showException(new Error('No file provided'));

            const fileData = formdataMapper({ file, csrf_token, column_id: columnId });

            upload<FileData>(uri, fileData, 'POST', (loaded, total) => this.showProgress(file.name, loaded, total)).then((data) => {
                this.addFileToField({ id: data.id, name: data.filename });
            }).then(
                () => { 
                    $(this.el.find('.progress-bar__container[data-file-name="' + file.name + '"]'))
                        .hide();
                }
            ).catch((e) => {
                this.handler.addError(e);
            });
        } catch (e) {
            this.showException(e instanceof Error ? e.message : e as string ?? e.toString());
        }
    }

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

    private async renameFile(fileId: number, oldName: string, newName: string, csrf_token: string, is_new: boolean = false) { // for some reason using the ev.target doesn't allow for changing of the data attribute - I don't know why, so I've used the button itself
        try {
            const filename = newName;
            const url = `/api/file/${fileId}`;
            const mappedData = formdataMapper({ csrf_token, filename, is_new: is_new ? 1 : 0 });
            const data = await upload<RenameResponse>(url, mappedData, 'PUT')
            if (is_new) {
                $(`#current-${fileId}`).text(data.name);
            } else {
                $(`#current-${fileId}`).closest('li').remove();
                const { id, name } = data;
                this.addFileToField({ id, name });
            }
        } catch (error) {
            this.showException(error);
            const current = $(`#current-${fileId}`);
            current.text(oldName);
        }
    }

    showException(e: any) {
        this.handler.addError(e);
    }
}

/**
 * Create a new document component
 * @param {JQuery<HTMLElement> | HTMLElement} el The element to attach the document component to
 */
export default function documentComponent(el: JQuery<HTMLElement> | HTMLElement) {
    const component = new DocumentComponent(el);
    component.init();
    return component;
}
