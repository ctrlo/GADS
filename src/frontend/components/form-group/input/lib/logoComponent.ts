import {formdataMapper} from 'util/mapper/formdataMapper';
import {upload} from 'util/upload/UploadControl';
import InputBase from './inputBase';

class LogoComponent extends InputBase {
  logoDisplay: JQuery<HTMLImageElement>;
  readonly type = 'logo';

  constructor(el: JQuery<HTMLElement> | HTMLElement) {
    super(el, '.form-control-file');
    this.logoDisplay = this.el.parent().find('img');
  }

  init() {
    if (this.logoDisplay.attr('src') === '#') {
      this.logoDisplay.hide();
    }

    this.el.find('.file').hide();

    this.input.on('change', this.handleFileChange);
  }

  handleFileChange = (ev: JQuery.ChangeEvent<HTMLInputElement>) => {
    ev.preventDefault();
    const url = this.el.data('fileupload-url');
    const file = this.input[0].files?.[0];
    const csrf_token = $('body').data('csrf');

    if (file) {
      const formData = formdataMapper({file, csrf_token});

      upload<{ url: string }>(url, formData, 'POST').then((data) => {
        const version = this.logoDisplay.attr('src')!.split('?')[1];
        const newVersion = version ? parseInt(version, 10) + 1 : 1;
        this.logoDisplay.attr('src', `${data.url}?${newVersion}`).show();
      });
    }
  };
}

const logoComponent = (el: JQuery<HTMLElement> | HTMLElement) => {
  const component = new LogoComponent(el);
  component.init();
  return component;
}

export default logoComponent;