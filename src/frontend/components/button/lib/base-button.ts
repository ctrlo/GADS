export abstract class BaseButton {
    abstract get type(): string;
    abstract click(ev?:JQuery.ClickEvent): void;
    
    init(): void {
        // noop
    }

    constructor(public element: JQuery<HTMLElement>) {
        this.init();

        this.element.on('click', (ev) => {
            this.click(ev);
        });
    }
}
