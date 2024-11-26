import { decrypt, encrypt } from "util/encryption";

class EncryptedStorage {
    private static _instance: EncryptedStorage;

    static instance() {
        if (!EncryptedStorage._instance) {
            EncryptedStorage._instance = new EncryptedStorage(encrypt, decrypt);
        }
        return EncryptedStorage._instance;
    }

    private storage: Storage;

    constructor(private encrypt: (data:string, key:string) => Promise<string>, private decrypt: (data:string, key:string) => Promise<string>, storage?: Storage) {
        this.storage = storage || window.localStorage;
    }

    async setItem(key: string, value: string, encryptionKey: string) {
        const encryptedValue = await this.encrypt(value, encryptionKey);
        this.storage.setItem(key, encryptedValue);
    }

    async getItem(key: string, encryptionKey: string) {
        const encryptedValue = this.storage.getItem(key);
        if (!encryptedValue) {
            return null;
        }
        return await this.decrypt(encryptedValue, encryptionKey);
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

export { EncryptedStorage };
