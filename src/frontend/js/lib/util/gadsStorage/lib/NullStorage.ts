import { AppStorage } from "./AppStorage";

/**
 * A storage implementation that does nothing. This is for when the browser does not support encryption.
 * @implements {AppStorage}
 */
export class NullStorage implements AppStorage {
    enabled: boolean = false;

    /**
     * @inheritdoc
     */
    setItem() {
        return Promise.resolve();
    }

    /**
     * @inheritdoc
     */
    getItem() {
        return Promise.resolve(null);
    }

    /**
     * @inheritdoc
     */
    removeItem() {
        return;
    }

    /**
     * @inheritdoc
     */
    clear() {
        return;
    }

    /**
     * @inheritdoc
     */
    key() {
        return null;
    }

    /**
     * @inheritdoc
     */
    length = 0;
}
