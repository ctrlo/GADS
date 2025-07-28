import { Progress } from "./Progress";
import { Renderable } from "../../common/Renderable";

/**
 * ProgressHandler is a class that manages multiple progress bars.
 */
export class ProgressHandler implements Renderable {
    /**
     * A record that holds all progress bars indexed by their identifiers.
     * Each key is a string identifier, and the value is an instance of Progress.
     */
    private bars: Record<string, Progress>;

    /**
     * 
     * @param parent The parent HTML element where the progress bars will be rendered.
     */
    public constructor(private readonly parent: HTMLElement) {
        this.bars = {};
    }

    /**
     * Creates a new progress bar and adds it to the handler.
     * @param {string} identifier A unique identifier for the progress bar.
     * @param {number} total The total value for the progress bar, default is 100.
     */
    public createBar(identifier: string, total: number=100) {
        const bar = new Progress(this.parent, identifier, total);
        this.bars[identifier] = bar;
        this.render();
    }

    /**
     * Update the value of an existing progress bar.
     * @param identifier The unique identifier of the progress bar to update.
     * @param value The new value to set for the progress bar.
     */
    public updateProgress(identifier: string, value: number) {
        if (this.bars[identifier]) {
            this.bars[identifier].value = value;
        } else {
            console.warn(`Progress bar with identifier "${identifier}" does not exist.`);
        }
        this.render();
    }

    /** @inheritdoc */
    public render() {
        Object.values(this.bars).forEach(bar => bar.render());
    }

    /**
     * Remove a progress bar from the handler and the DOM.
     * @param {string} identifier The unique identifier of the progress bar to remove.
     */
    public remove(identifier: string) {
        if (this.bars[identifier]) {
            delete this.bars[identifier];
            const progressbar = $(`[data-identifier="${identifier}"]`);
            if (progressbar.length > 0) {
                progressbar.remove();
            }
        } else {
            console.warn(`Progress bar with identifier "${identifier}" does not exist.`);
        }
    }
}
