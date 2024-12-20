import InputBase from "./inputBase";

class PasswordComponent extends InputBase {
  readonly type = 'password';

  btnReveal: JQuery<HTMLElement>;
  
  constructor(el: JQuery<HTMLElement> | HTMLElement) {
    super(el);
    this.btnReveal = this.el.find('.input__reveal-password');
  }

  init() {
    if (this.btnReveal.length === 0) return;

    this.btnReveal.removeClass('show').on('click', this.handleClickReveal);
  }

  private handleClickReveal = () => {
    const inputType = this.input.attr('type');
    this.input.attr('type', inputType === 'password' ? 'text' : 'password');
    this.btnReveal.toggleClass('show');
  };
}

const passwordComponent = (el: JQuery<HTMLElement> | HTMLElement) => {
  const component = new PasswordComponent(el)
  component.init();
  return component;
}

export default passwordComponent;
