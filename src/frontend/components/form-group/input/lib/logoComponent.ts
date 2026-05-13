import { formdataMapper } from 'util/mapper/formdataMapper';
import { upload } from 'util/upload/UploadControl';

/**
 * LogoComponent class for handling logo upload functionality.
 */
class LogoComponent {
    el: JQuery<HTMLElement>;
    logoDisplay: JQuery<HTMLImageElement>;
    fileInput: JQuery<HTMLInputElement>;
    protected readonly type = 'logo';

    /**
     * Create a new LogoComponent.
     * @param {JQuery<HTMLElement> | HTMLElement} el The HTML element for the logo component, can be a jQuery object or a plain HTMLElement.
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.logoDisplay = this.el.parent().find('img');
        this.fileInput = this.el.find('.form-control-file') as JQuery<HTMLInputElement>;
    }

    /**
     * Initialize the LogoComponent.
     */
    init() {
        if (this.logoDisplay.attr('src') === '#') {
            this.logoDisplay.hide();
        }

        this.el.find('.file').hide();

        this.fileInput.on('change', this.handleFileChange);
    }

    /**
     * Handle the file input change event to upload the selected file.
     * @param {JQuery.ChangeEvent<HTMLInputElement>} ev The change event triggered when a file is selected.
     */
    handleFileChange = (ev: JQuery.ChangeEvent<HTMLInputElement>) => {
        ev.preventDefault();
        const url = this.el.data('fileupload-url');
        const file = this.fileInput[0].files?.[0];
        const csrf_token = $('body').data('csrf');

        if (file) {
            const formData = formdataMapper({ file, csrf_token });

            upload<{ url: string }>(url, formData, 'POST').then((data) => {
                const version = this.logoDisplay.attr('src')!.split('?')[1];
                const newVersion = version ? parseInt(version, 10) + 1 : 1;
                this.logoDisplay.attr('src', `${data.url}?${newVersion}`).show();
            });
        }
    };
}

/**
 * Create a new LogoComponent.
 * @param {HTMLElement} el The HTML element for the logo component.
 */
export default function logoComponent(el: JQuery<HTMLElement> | HTMLElement) {
    const component = new LogoComponent(el);
    component.init();
}
