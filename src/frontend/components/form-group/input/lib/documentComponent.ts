import 'components/button/lib/rename-button';
import { upload } from 'util/upload/UploadControl';
import { validateCheckboxGroup } from 'validation';
import { formdataMapper } from 'util/mapper/formdataMapper';
import { logging } from 'logging';
import { checkFilename } from './filenameChecker';

interface RenameEvent extends JQuery.Event {
    target: HTMLButtonElement;
    newName: string;
}

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
    readonly error: JQuery<HTMLElement>;

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        $('.rename').renameButton().on('rename', async (ev: RenameEvent) => {
            logging.log('rename', ev);
            if (!ev) throw new Error("e is not a RenameEvent - this shouldn't happen!")
            const $target = $(ev.target);
            await this.renameFile($target.data('field-id'), ev.newName, $('body').data('csrf'));
        });
        this.fileInput = this.el.find<HTMLInputElement>('.form-control-file');
        this.error = this.el.find('.upload__error');
    }

    async init() {
        const url = this.el.data('fileupload-url');

        const tokenField = this.el.closest('form').find('input[name="csrf_token"]');
        const csrf_token = tokenField.val() as string;
        const dropTarget = this.el.closest('.file-upload');

        if (dropTarget) {
            const dragOptions = { allowMultiple: false };
            dropTarget.filedrag(dragOptions).on('onFileDrop', async (_: JQuery.DropEvent, file: File) => {
                await this.handleAjaxUpload(url, csrf_token, file);
            });
        } else {
            throw new Error('Could not find file-upload element');
        }

        $('[name="file"]').on('change', async (ev) => {
            if (!(ev.target instanceof HTMLInputElement)) {
                throw new Error('Could not find file-upload element');
            }

            try {
                const file = ev.target.files![0];
                if (!file || file === undefined || !file.name) return;
                const formData = formdataMapper({ file, csrf_token });

                this.showContainer();
                const data = await upload<FileData>(url, formData, 'POST', (loaded, total) => {
                    let uploadProgression = Math.round((loaded / total) * 10000) / 100;
                    if (uploadProgression == Infinity) uploadProgression = 100;
                    this.el.find('.progress-bar__percentage').html(uploadProgression === 100 ? 'complete' : `${uploadProgression}%`);
                    this.el.find('.progress-bar__progress').css('width', `${uploadProgression}%`);
                });
                this.addFileToField({ id: data.id, name: data.filename });
            } catch (error) {
                this.showException(error);
                return;
            }
        });
    }

    async handleAjaxUpload(uri: string, csrf_token: string, file: File) {
        try {
            this.error.hide();
            if (!file) throw this.showException('No file provided');

            const fileData = formdataMapper({ file, csrf_token });

            this.showContainer();
            const data = await upload<FileData>(uri, fileData, 'POST', (loaded, total) => {
                let uploadProgression = Math.round((loaded / total) * 10000) / 100;
                if (uploadProgression == Infinity) uploadProgression = 100;
                this.el.find('.progress-bar__percentage').html(`${uploadProgression}%`);
                this.el.find('.progress-bar__progress').css('width', `${uploadProgression}%`);
            })
            this.addFileToField({ id: data.id, name: data.filename });
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
            logging.log('rename', ev);
            await this.renameFile(fileId as number ?? parseInt(fileId.toString()), ev.newName, csrf_token, true);
        });
    }

    private async renameFile(fileId: number, newName: string, csrf_token: string, is_new: boolean = false) { // for some reason using the ev.target doesn't allow for changing of the data attribute - I don't know why, so I've used the button itself
        try {
            checkFilename(newName);
            const url = `/api/file/${fileId}`;
            const mappedData = formdataMapper({ csrf_token, filename: newName, is_new: is_new ? 1 : 0 });
            const data = await upload<RenameResponse>(url, mappedData, 'PUT')
            logging.log('renameFile', data);
            if (is_new) {
                $(`#current-${fileId}`).text(data.name);
            } else {
                $(`#current-${fileId}`).closest('li').remove();
                const { id, name } = data;
                this.addFileToField({ id, name });
            }
        } catch (error) {
            this.showException(error);
        }
    }

    showContainer() {
        const container = $(this.el.find('.progress-bar__container'))
        container.show()
    }

    showException(e: string | Error) {
        this.showContainer();
        this.el.find('.progress-bar__container').css('width', '100%');
        this.el.find('.progress-bar__progress').addClass('progress-bar__container--fail');
        this.error.html(e instanceof Error ? e.message ? e.message : e.toString() : e);
        $(this.error).show();
    }
}

/**
 * Create a new document component
 * @param {JQuery<HTMLElement> | HTMLElement} el The element to attach the document component to
 */
export default function documentComponent(el: JQuery<HTMLElement> | HTMLElement) {
    Promise.all([(new DocumentComponent(el)).init()]);
}
