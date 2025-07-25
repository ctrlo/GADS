import { decrypt, encrypt } from 'util/encryption';

/**
 * EncryptedStorage is a wrapper around the localStorage API that encrypts and decrypts data before storing it.
 */
class EncryptedStorage {
    private static _instance: EncryptedStorage;

    /**
     * Returns the singleton instance of EncryptedStorage.
     * @returns {EncryptedStorage} The singleton instance of EncryptedStorage
     */
    static instance(): EncryptedStorage {
        if (!EncryptedStorage._instance) {
            EncryptedStorage._instance = new EncryptedStorage(encrypt, decrypt);
        }
        return EncryptedStorage._instance;
    }

    /**
     * Create a new EncryptedStorage instance.
     * @param {(string, string)=>Promise<string>} encrypt The function to encrypt data (this is to make it pluggable for different encryption algorithms should it be required)
     * @param {(string,string)=>Promise<string>} decrypt The function to decrypt data (this is to make it pluggable for different encryption algorithms should it be required)
     * @param {Storage} storage The storage provider to use (defaults to window.localStorage)
     */
    constructor(private encrypt: (data: string, key: string) => Promise<string>, private decrypt: (data: string, key: string) => Promise<string>, private storage: Storage = localStorage) {
    }

    /**
     * Store an item in the encrypted storage.
     * @param {string} key The key to store the value under
     * @param {string} value The value to store
     * @param {string} encryptionKey The key to use to encrypt the value
     */
    async setItem(key: string, value: string, encryptionKey: string) {
        const encryptedValue = await this.encrypt(value, encryptionKey);
        this.storage.setItem(key, encryptedValue);
    }

    /**
     * Get an item from the encrypted storage.
     * @param {string} key The key to retrieve the value for
     * @param {string} encryptionKey The key to use to decrypt the value
     * @returns {Promise<string | null>} The decrypted value, or null if the key does not exist
     */
    async getItem(key: string, encryptionKey: string): Promise<string | null> {
        const encryptedValue = this.storage.getItem(key);
        if (!encryptedValue) {
            return null;
        }
        return await this.decrypt(encryptedValue, encryptionKey);
    }

    /**
     * Remove an item from the encrypted storage.
     * @param {string} key The key to remove from the storage
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
     * @param {number} index The index of the key to retrieve
     * @returns {string} The key at the given index
     */
    key(index: number): string {
        return this.storage.key(index);
    }

    /**
     * Get the number of items in the encrypted storage.
     * @returns {number} The number of items in the storage
     */
    get length(): number {
        return this.storage.length;
    }
}

export { EncryptedStorage };
