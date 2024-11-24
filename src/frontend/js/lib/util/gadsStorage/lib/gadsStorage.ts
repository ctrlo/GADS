import { EncryptedStorage } from "util/encryptedStorage";

class GadsStorage {
    private storage: EncryptedStorage;
    private storageKey: string;

    constructor() {
        this.storage = EncryptedStorage.instance();
    }

    private async getStorageKey() {
        const fetchResult = await fetch("/get_key");
        const data = await fetchResult.json();
        if(data.error !== 0) {
            throw new Error("Failed to get storage key");
        }
        this.storageKey = data.key;
    }

    async setItem(key: string, value: string) {
        if(!this.storageKey) {
            await this.getStorageKey();
        }
        await this.storage.setItem(key, value, this.storageKey);
    }

    async getItem(key: string) {
        if(!this.storageKey) {
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

export { GadsStorage };