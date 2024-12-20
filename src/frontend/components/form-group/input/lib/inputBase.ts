abstract class InputBase {
    abstract get type(): string;

    input: JQuery<HTMLInputElement>;
    el: JQuery<HTMLElement>;

    constructor(el: HTMLElement | JQuery<HTMLElement>, controlId: string = '.form-control') {
        this.el = $(el);
        this.input = this.el.find<HTMLInputElement>(controlId);
    }

    abstract init(): void;
}

export default InputBase;