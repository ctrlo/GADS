import { decrypt, encrypt } from 'util/encryption';

/**
 * EncryptedStorage is a wrapper around the localStorage API that encrypts and decrypts data before storing it.
 */
class EncryptedStorage {
    private static _instance: EncryptedStorage;

    /**
     * Returns the singleton instance of EncryptedStorage.
     */
    static instance() {
        if (!EncryptedStorage._instance) {
            EncryptedStorage._instance = new EncryptedStorage(encrypt, decrypt);
        }
        return EncryptedStorage._instance;
    }

    /**
     * The underlying storage object.
     */
    private storage: Storage;

    /**
     * Create a new EncryptedStorage instance.
     * @param encrypt The function to encrypt data (this is to make it pluggable for different encryption algorithms should it be required)
     * @param decrypt The function to decrypt data (this is to make it pluggable for different encryption algorithms should it be required)
     * @param storage The storage provider to use (defaults to window.localStorage)
     */
    constructor(private encrypt: (data: string, key: string) => Promise<string>, private decrypt: (data: string, key: string) => Promise<string>, storage?: Storage) {
        this.storage = storage || window.localStorage;
    }

    /**
     * Store an item in the encrypted storage.
     * @param key The key to store the value under
     * @param value The value to store
     * @param encryptionKey The key to use to encrypt the value
     */
    async setItem(key: string, value: string, encryptionKey: string) {
        const encryptedValue = await this.encrypt(value, encryptionKey);
        this.storage.setItem(key, encryptedValue);
    }

    /**
     * Get an item from the encrypted storage.
     * @param key The key to retrieve the value for
     * @param encryptionKey The key to use to decrypt the value
     * @returns The decrypted value, or null if the key does not exist
     */
    async getItem(key: string, encryptionKey: string) {
        const encryptedValue = this.storage.getItem(key);
        if (!encryptedValue) {
            return null;
        }
        return await this.decrypt(encryptedValue, encryptionKey);
    }

    /**
     * Remove an item from the encrypted storage.
     * @param key The key to remove from the storage
     */
    removeItem(key: string) {
        this.storage.removeItem(key);
    }

    /**
     * Clear all items from the encrypted storage.
     */
    clear() {
        this.storage.clear();
    }

    /**
     * Get the key at a given index in the encrypted storage.
     * @param index The index of the key to retrieve
     * @returns The key at the given index
     */
    key(index: number) {
        return this.storage.key(index);
    }

    /**
     * Get the number of items in the encrypted storage.
     */
    get length() {
        return this.storage.length;
    }
}

export { EncryptedStorage };
