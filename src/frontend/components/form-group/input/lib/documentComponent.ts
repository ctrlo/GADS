import '../../../button/lib/rename-button';
import { upload } from 'util/upload/UploadControl';
import { validateCheckboxGroup } from 'validation';
import { hideElement, showElement } from 'util/common';
import { formdataMapper } from 'util/mapper/formdataMapper';
import { RenameEvent } from '../../../button/lib/rename-button';

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
    fileInput: JQuery<HTMLInputElement>;
    error: JQuery<HTMLElement>;

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        // @ts-expect-error Event handling is a bit weird
        $('.rename').renameButton().on('rename', (ev: RenameEvent)=>{
            if(this.debug || window.test) console.log('rename', ev);
            const $target = $(ev.target);
            this.renameFile($target.data('field-id'), ev.newName, $('body').data('csrf'));
        });
        this.fileInput = this.el.find<HTMLInputElement>('.form-control-file');
        this.error = this.el.find('.upload__error');
    }

    debug = location.hostname === 'localhost';

    init() {
        const url = this.el.data('fileupload-url');

        const tokenField = this.el.closest('form').find('input[name="csrf_token"]');
        const csrf_token = tokenField.val() as string;
        const dropTarget = this.el.closest('.file-upload');

        if (dropTarget) {
            const dragOptions = { allowMultiple: false };
            dropTarget.filedrag(dragOptions).on('onFileDrop', (_ev: JQuery.DropEvent, file: File) => {
                this.handleAjaxUpload(url, csrf_token, file);
            });
        } else {
            throw new Error('Could not find file-upload element');
        }

        $('[name="file"]').on('change', (ev) => {
            if (!(ev.target instanceof HTMLInputElement)) {
                throw new Error('Could not find file-upload element');
            }

            const file = ev.target.files![0];
            const formData = formdataMapper({ file, csrf_token });

            upload<FileData>(url, formData, 'POST', (loaded, total) => {
                if (!this.el.data('multivalue')) {
                    const uploadProgression = Math.round((loaded / total) * 10000) / 100 + '%';
                    this.el.find('.progress-bar__percentage').html(uploadProgression);
                    this.el.find('.progress-bar__progress').css('width', uploadProgression);
                }
            }).then((data) => {
                this.addFileToField({ id: data.id, name: data.filename });
            }).catch((error) => {
                this.showException(error);
                return;
            });
        });
    }

    handleAjaxUpload(uri: string, csrf_token: string, file: File) {
        hideElement(this.error);
        if (!file) throw this.showException('No file provided');

        const fileData = formdataMapper({ file, csrf_token });

        upload<FileData>(uri, fileData, 'POST', (loaded, total) => {
            if (!this.el.data('multivalue')) {
                const uploadProgression = Math.round((loaded / total) * 10000) / 100 + '%';
                this.el.find('.progress-bar__percentage').html(uploadProgression);
                this.el.find('.progress-bar__progress').css('width', uploadProgression);
            }
        }).then((data) => {
            this.addFileToField({ id: data.id, name: data.filename });
        }).catch((e) => {
            this.showException(e);
        });
    }

    addFileToField(file: { id: number | string; name: string }) {
        const $fieldset = this.el.closest('.fieldset');
        const $ul = $fieldset.find('.fileupload__files');
        const fileId = file.id;
        const fileName = file.name;
        const field = $fieldset.find('.input--file').data('field');
        const csrf_token = $('body').data('csrf');

        if (!this.el || !this.el.length || !this.el.data('multivalue')) $ul.empty();

        const $li = $(`
            <li class="list__item">
                <div class="row w-full">
                    <div class="col-auto">
                        <input type="checkbox" id="file-${fileId}" name="${field}" value="${fileId}"
                            aria-label="${fileName}" data-filename="${fileName}" checked="">
                        <label for="file-${fileId}">Include File. Current file name:</label>
                        <a id="current-${fileId}" class="link link--plain"
                            href="/file/${fileId}">${fileName}</a>
                        <button data-field-id="${fileId}" class="rename btn btn-plain"
                            title="Rename file" type="button"></button>
                    </div>
                    <div class="col">
                        <input type="text" id="file-rename-${fileId}" name="file-rename-${fileId}" value="${fileName}" class="input input--text form-control" aria-hidden="true">
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
        // @ts-expect-error Event handling is a bit weird
        $button.renameButton().on('rename', (ev: RenameEvent)=>{
            if(this.debug || window.test) console.log('rename', ev);
            this.renameFile(fileId as number ?? parseInt(fileId.toString()), ev.newName, csrf_token, true);
        });
    }

    private renameFile(fileId:number, newName:string, csrf_token: string, is_new: boolean = false) { // for some reason using the ev.target doesn't allow for changing of the data attribute - I don't know why, so I've used the button itself
        if(this.debug || window.test) console.log('renameFile', fileId, newName, csrf_token, is_new);
        const url = `/api/file/${fileId}`;
        const data = formdataMapper({ csrf_token, filename: newName, is_new: is_new ? 1 : 0 });
        upload<RenameResponse>(url, data, 'PUT').then((data) => {
            if(this.debug || window.test) console.log('renameFile', data);
            if (is_new) {
                $(`#current-${fileId}`).text(data.name);
            } else {
                this.addFileToField({ id: data.id, name: data.name });
            }
        }).catch((error) => {
            this.showException(error);
        });
    }

    showException(e: string | Error) {
        this.el.find('.progress-bar__container').css('width', '100%');
        this.el.find('.progress-bar__progress').addClass('progress-bar__container--fail');
        this.error.html(e instanceof Error ? e.message : e);
        showElement(this.error);
    }
}

/**
 * Create a new document component
 * @param {JQuery<HTMLElement> | HTMLElement} el The element to attach the document component to
 */
export default function documentComponent(el: JQuery<HTMLElement> | HTMLElement) {
    new DocumentComponent(el).init();
}
