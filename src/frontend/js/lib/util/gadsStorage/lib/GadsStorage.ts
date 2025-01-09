import { EncryptedStorage } from "util/encryptedStorage";
import { AppStorage } from "./AppStorage";

/**
 * A storage provider that encrypts data before storing it in the browser.
 */
export class GadsStorage implements AppStorage {
    test = false; //location.hostname==="localhost"; // Set to true to use localStorage instead of EncryptedStorage

    enabled: boolean = true;

    private storage: EncryptedStorage | Storage;
    private storageKey: string;

    constructor() {
        this.test && console.log("Using localStorage");
        this.storage = this.test ? localStorage : EncryptedStorage.instance();
    }

    private async getStorageKey() {
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

    async setItem(key: string, value: string) {
        if(await this.getItem('recovering')) return;
        if(await this.getItem(key) === value) return;
        if (!this.storageKey) {
            await this.getStorageKey();
        }
        await this.storage.setItem(key, value, this.storageKey);
    }

    async getItem(key: string) {
        if (!this.storageKey) {
            await this.getStorageKey();
        }
        return await this.storage.getItem(key, this.storageKey);
    }

    removeItem(key: string) {
        this.storage.removeItem(key);
    }

    clear() {
        this.storage.clear();
    }

    key(index: number) {
        return this.storage.key(index);
    }

    get length() {
        return this.storage.length;
    }
}
