import { upload } from 'util/upload/UploadControl';
import { validateCheckboxGroup } from 'validation';
import { hideElement, showElement } from 'util/common';
import { formdataMapper } from 'util/mapper/formdataMapper';

interface FileData {
    id: number | string;
    filename: string;
}

class DocumentComponent {
    readonly type = 'document';
    el: JQuery<HTMLElement>;
    fileInput: JQuery<HTMLInputElement>;
    error: JQuery<HTMLElement>;

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = el instanceof HTMLElement ? $(el) : el;
        this.fileInput = this.el.find<HTMLInputElement>('.form-control-file');
        this.error = this.el.find('.upload__error');
    }

    init() {
        const url = this.el.data('fileupload-url');
        const $progressBarContainer = this.el.find('.progress-bar__container');
        const $progressBarProgress = this.el.find('.progress-bar__progress');

        const tokenField = this.el.closest('form').find('input[name="csrf_token"]');
        const csrf_token = tokenField.val() as string;
        const dropTarget = this.el.closest('.file-upload');

        if (dropTarget) {
            const dragOptions = { allowMultiple: false };
            (<any>dropTarget).filedrag(dragOptions).on('onFileDrop', (_ev: JQuery.DropEvent, file: File) => { // eslint-disable-line @typescript-eslint/no-explicit-any
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

            upload<FileData>(url, formData, 'POST', this.updateProgress).then((data) => {
                this.addFileToField({ id: data.id, name: data.filename });
            }).catch((error) => {
                $progressBarProgress.css('width', '100%');
                $progressBarContainer.addClass('progress-bar__container--fail');
                this.showException(error);
            });
        });
    }

    handleAjaxUpload(uri: string, csrf_token: string, file: File) {
        hideElement(this.error);
        if (!file) throw this.showException('No file provided');

        const fileData = formdataMapper({ file, csrf_token });

        upload<FileData>(uri, fileData, 'POST', this.updateProgress)
            .then((data) => {
                this.addFileToField({ id: data.id, name: data.filename });
            })
            .catch((e) => {
                this.showException(e);
            });
    }

    addFileToField(file: { id: number | string; name: string }) {
        const $fieldset = this.el.closest('.fieldset');
        const $ul = $fieldset.find('.fileupload__files');
        const fileId = file.id;
        const fileName = file.name;
        const field = $fieldset.find('.input--file').data('field');

        if (!this.el.data('multivalue')) {
            $ul.empty();
        }

        const $li = $(`
            <li class="help-block">
                <div class="checkbox">
                    <input type="checkbox" id="file-${fileId}" name="${field}" value="${fileId}" aria-label="${fileName}" data-filename="${fileName}" checked>
                    <label for="file-${fileId}">
                        <span>Include file. Current file name: <a class="link" href="/file/${fileId}">${fileName}</a>.</span>
                    </label>
                </div>
            </li>
        `);

        $ul.append($li);
        $ul.closest('.linkspace-field').trigger('change');
        validateCheckboxGroup($fieldset.find('.list'));
        $fieldset.find('input[type="file"]').removeAttr('required');
    }

    showException(e: string | Error) {
        this.error.html(e instanceof Error ? e.message : e);
        showElement(this.error);
    }

    private updateProgress(loaded: number, total: number) {
        if (!this.el.data('multivalue')) {
            const uploadProgression = Math.round((loaded / total) * 10000) / 100 + '%';
            this.el.find('.progress-bar__percentage').html(uploadProgression);
            this.el.find('.progress-bar__progress').css('width', uploadProgression);
        }
    }
}

export default function documentComponent(el: JQuery<HTMLElement> | HTMLElement) {
    new DocumentComponent(el).init();
}
