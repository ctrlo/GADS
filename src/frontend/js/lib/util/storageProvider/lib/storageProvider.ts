import gadsStorage from 'util/gadsStorage';
import { AppStorage } from 'util/gadsStorage/lib/AppStorage';
import { fromJson } from 'util/common';

/**
 * StorageProvider class for managing storage operations
 */
class StorageProvider {
    /**
     * Get the storage provider instance
     * @returns {Storage | AppStorage} The storage provider instance
     */
    get provider() { return this.storage; }

    /**
     * Create a new StorageProvider instance
     * @param {string} instance The instance name for the storage
     * @param {Storage | AppStorage} storage The storage to use, defaults to gadsStorage
     */
    constructor(private readonly instance: string, private readonly storage: Storage | AppStorage = gadsStorage) {
    }

    /**
     * Set an item in the storage
     * @param {string} key The key to set the item for
     * @param {string} value The value to set for the key
     */
    async setItem(key: string, value: string) {
        let item = await this.storage.getItem(this.instance);
        if (!item) item = '{}';
        const map: Record<string,string> = fromJson(item);
        map[key] = value;
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }

    /**
     * Get an item from the storage
     * @param {string} key The key to get the item for
     * @returns {Promise<string | undefined>} The value for the key, or undefined if not found
     */
    async getItem(key: string): Promise<string | undefined> {
        const item = await this.storage.getItem(this.instance);
        if (!item) return undefined;
        const map: Record<string,string> = fromJson(item);
        return map[key] || undefined;
    }

    /**
     * Get all items from the storage
     * @returns {Promise<string,string>} All items in the storage as a key-value map
     */
    async getAll(): Promise<Record<string,string>> {
        const item = await this.storage.getItem(this.instance);
        if (!item) return {};
        return fromJson(item);
    }

    /**
     * Clear all items in the storage for this instance
     */
    async clear() {
        this.storage.removeItem(this.instance);
    }

    /**
     * Remove an item from the storage
     * @param {string} key The key to remove the item for
     */
    async removeItem(key: string) {
        const item = await this.storage.getItem(this.instance);
        if (!item) return;
        const map: Record<string,string> = fromJson(item);
        delete map[key];
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }
}

export default StorageProvider;
