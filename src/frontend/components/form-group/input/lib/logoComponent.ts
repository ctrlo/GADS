import { formdataMapper } from 'util/mapper/formdataMapper';
import { upload } from 'util/upload/UploadControl';

/**
 * Logo component for uploading and modifying logos for reports
 */
class LogoComponent {
    el: JQuery<HTMLElement>;
    logoDisplay: JQuery<HTMLImageElement>;
    fileInput: JQuery<HTMLInputElement>;
    protected readonly type = 'logo';

    /**
     * Create a new LogoComponent
     * @param el The element to attach the component to
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.logoDisplay = this.el.parent().find('img');
        this.fileInput = this.el.find('.form-control-file') as JQuery<HTMLInputElement>;
    }

    /**
     * Initialize the logo component
     */
    init() {
        if (this.logoDisplay.attr('src') === '#') {
            this.logoDisplay.hide();
        }

        this.el.find('.file').hide();

        this.fileInput.on('change', this.handleFileChange);
    }

    /**
     * Handle change of the file input
     * @param ev The event triggered when the file input changes
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
 * Create a new LogoComponent
 * @param el The element to attach the component to
 */
export default function logoComponent(el: JQuery<HTMLElement> | HTMLElement) {
    (new LogoComponent(el))
        .init();
}
