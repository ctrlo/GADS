import { upload } from 'util/upload/UploadControl';
import { validateCheckboxGroup } from 'validation';
import { hideElement, showElement } from 'util/common';
import { formdataMapper } from 'util/mapper/formdataMapper';

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
        this.fileInput = this.el.find<HTMLInputElement>('.form-control-file');
        this.error = this.el.find('.upload__error');
    }

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
                <span class="list__key sr-only">
                    <label for="file-rename-${fileId}">Rename file</label>
                </span>
                <span class="list__value">
                    <span class="row">
                        <span class="col-10">                
                            <input type="text" id="file-rename-${fileId}" name="file-rename-${fileId}" value="${fileName}" class="input input--text form-control">
                        </span>
                        <span class="col-2">
                            <button id="rename-${fileId}" class="btn btn-default" data-file-id="${fileId}" data-original-name="${fileName}" type="button">Rename</button>
                        </span>
                    </span>
                </span>
            </li>
            <li class="list__item">
                <span class="list__key">
                    <input type="checkbox" id="file-${fileId}" name="${field}" value="${fileId}" aria-label="${fileName}" data-filename="${fileName}" checked>
                </span>
                <span class="list__value">Include File. Current file name: <a id="current-${fileId}" class="link link--plain" href="/file/${fileId}">${fileName}</a>.</span>
            </li>
        `);

        $ul.append($li);
        $ul.closest('.linkspace-field').trigger('change');
        validateCheckboxGroup($fieldset.find('.list'));
        $fieldset.find('input[type="file"]').removeAttr('required');
        const button = `#rename-${fileId}`;
        const $button = $(button);
        console.log(`Adding click to ${button}`);

        $(button).on('click', () => this.handleRename($button, csrf_token));
    }

    private handleRename($button: JQuery<HTMLElement>, csrf_token: string) { // for some reason using the ev.target doesn't allow for changing of the data attribute - I don't know why, so I've used the button itself
        const fileId = $button.data('file-id');
        const originalName = $button.data('original-name');
        const ext = "." + originalName.split('.').pop();
        const newName = $(`#file-rename-${fileId}`).val() as string;
        if ((newName.endsWith(ext) ? newName : newName + ext) === originalName) return;
        const url = `/api/file`;
        const data = formdataMapper({ csrf_token, rename: fileId, filename: newName.endsWith(ext) ? newName : newName + ext });
        upload<RenameResponse>(url, data, 'POST').then((data) => {
            console.log("renamed", data);
            console.log("BUTTON", $button)
            $button.data('original-name', data.name);
            $(`#current-${fileId}`).text(data.name);
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

export default function documentComponent(el: JQuery<HTMLElement> | HTMLElement) {
    new DocumentComponent(el).init();
}
