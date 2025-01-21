import { EncryptedStorage } from "util/encryptedStorage";
import { AppStorage } from "./AppStorage";

/**
 * A storage provider that encrypts data before storing it in the browser.
 */
export class GadsStorage implements AppStorage {
    test = false; // location.hostname==="localhost"; // Set to true to use localStorage instead of EncryptedStorage

    enabled: boolean = true;

    private storage: EncryptedStorage | Storage;
    private storageKey: string;

    /**
     * Creates a new GadsStorage instance.
     */
    constructor() {
        this.test && console.log("Using localStorage");
        this.storage = this.test ? localStorage : EncryptedStorage.instance();
    }

    /**
     * Fetches the storage key used to encrypt data.
     * @returns The storage key used to encrypt data.
     */
    private async getStorageKey() {
        //@ts-expect-error This is for unit tests
        if (window.test) { 
            this.storageKey = "test";
            return;
        }
        const fetchResult = await fetch("/api/get_key");
        const data = await fetchResult.json();
        if (data.error !== 0) {
            throw new Error("Failed to get storage key");
        }
        this.storageKey = data.key;
    }

    /**
     * @inheritdoc
     */
    async setItem(key: string, value: string) {
        // We turn off writing if we're performing a recovery to prevent extra write operations—this is more to prevent 
        // the odd curval error with dropdowns. It's felt it's more sensible to do this here, rather than search through
        // all the code and try to work out where to put the check (and repeat it ad infinitum)
        if(await this.getItem('recovering')) return;
        if(await this.getItem(key) === value) return;
        if (!this.storageKey) {
            await this.getStorageKey();
        }
        await this.storage.setItem(key, value, this.storageKey);
    }

    /**
     * @inheritdoc
     */
    async getItem(key: string) {
        if (!this.storageKey) {
            await this.getStorageKey();
        }
        return await this.storage.getItem(key, this.storageKey);
    }

    /**
     * @inheritdoc
     */
    removeItem(key: string) {
        this.storage.removeItem(key);
    }

    /**
     * @inheritdoc
     */
    clear() {
        this.storage.clear();
    }

    /**
     * @inheritdoc
     */
    key(index: number) {
        return this.storage.key(index);
    }

    /**
     * @inheritdoc
     */
    get length() {
        return this.storage.length;
    }
}
