import { formdataMapper } from 'util/mapper/formdataMapper';
import { upload } from 'util/upload/UploadControl';

class LogoComponent {
    el: JQuery<HTMLElement>;
    logoDisplay: JQuery<HTMLImageElement>;
    fileInput: JQuery<HTMLInputElement>;
    protected readonly type = 'logo';

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.logoDisplay = this.el.parent().find('img');
        this.fileInput = this.el.find('.form-control-file') as JQuery<HTMLInputElement>;
    }

    init() {
        if (this.logoDisplay.attr('src') === '#') {
            this.logoDisplay.hide();
        }

        this.el.find('.file').hide();

        this.fileInput.on('change', this.handleFileChange);
    }

    handleFileChange = async (ev: JQuery.ChangeEvent<HTMLInputElement>) => {
        ev.preventDefault();
        const url = this.el.data('fileupload-url');
        const file = this.fileInput[0].files?.[0];
        const csrf_token = $('body').data('csrf');

        if (file) {
            const formData = formdataMapper({ file, csrf_token });

            const data = await upload<{ url: string }>(url, formData, 'POST')
                const version = this.logoDisplay.attr('src')!.split('?')[1];
                const newVersion = version ? parseInt(version, 10) + 1 : 1;
                this.logoDisplay.attr('src', `${data.url}?${newVersion}`).show();
        }
    };
}

export default function logoComponent(el: JQuery<HTMLElement> | HTMLElement) {
    const component = new LogoComponent(el);
    component.init();
}
