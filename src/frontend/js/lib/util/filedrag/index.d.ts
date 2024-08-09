import { FileDragOptions } from "./lib/filedrag";

declare global {
    interface JQuery<TElement = HTMLElement> {
        filedrag(options: FileDragOptions): JQuery<TElement>;
    }
}

export {}