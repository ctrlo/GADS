import gadsStorage from "util/gadsStorage";
import { AppStorage } from "util/gadsStorage/lib/AppStorage";
import { fromJson } from "util/common"

/**
 * Map of key/value pairs for string storage
 */
type StringMap = { [key: string]: string };

/**
 * A simple storage provider that uses the browser's local storage or a custom storage implementation.
 */
class StorageProvider {
    /**
     * Get the storage provider
     */
    get provider() { return this.storage; }

    /**
     * Create a new storage provider
     * @param instance The instance that this storage provider is associated with.
     * @param storage The storage type to use
     */
    constructor(private readonly instance: string, private readonly storage: Storage | AppStorage = gadsStorage) {
    }

    /**
     * Set an item in the storage
     * @param key The key for the value to set
     * @param value The value to set
     */
    async setItem(key: string, value: string) {
        let item = await this.storage.getItem(this.instance);
        if (!item) item = '{}';
        const map: StringMap = fromJson(item);
        map[key] = value;
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }

    /**
     * Get an item from the storage
     * @param key The key to get
     * @returns The Promise of the value or undefined if not found
     */
    async getItem(key: string): Promise<string | undefined> {
        const item = await this.storage.getItem(this.instance);
        if (!item) return undefined;
        const map: StringMap = fromJson(item);
        return map[key] || undefined;
    }

    /**
     * Get all items in the storage
     * @returns All items in the storage
     */
    async getAll(): Promise<StringMap> {
        const item = await this.storage.getItem(this.instance);
        if (!item) return {};
        return fromJson(item);
    }

    /**
     * Clear all items in the storage
     */
    async clear() {
        this.storage.removeItem(this.instance);
    }

    /**
     * Remove an item from storage
     */
    async removeItem(key: string) {
        const item = await this.storage.getItem(this.instance);
        if (!item) return;
        const map: StringMap = fromJson(item);
        delete map[key];
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }
}

export default StorageProvider;