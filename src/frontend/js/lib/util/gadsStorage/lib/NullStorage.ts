import { AppStorage } from "./AppStorage";

/**
 * A storage implementation that does nothing. This is for when the browser does not support encryption.
 * @implements {AppStorage}
 */
export class NullStorage implements AppStorage {
    enabled: boolean = false;

    setItem() {
        return Promise.resolve();
    }

    getItem() {
        return Promise.resolve(null);
    }

    removeItem() {
        return;
    }

    clear() {
        return;
    }

    key() {
        return null;
    }

    length = 0;
}
