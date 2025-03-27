import gadsStorage from "util/gadsStorage";
import { AppStorage } from "util/gadsStorage/lib/AppStorage";
import { fromJson } from "util/common"

type StringMap = { [key: string]: string };

/**
 * StorageProvider is a class that provides a simple interface to store and retrieve key-value pairs.
 */
class StorageProvider {
    get provider() { return this.storage; }

    /**
     * Create a new StorageProvider instance.
     * @param instance The instance to store the key-value pairs under
     * @param storage The storage to use. Defaults to gadsStorage
     */
    constructor(private readonly instance: string, private readonly storage: Storage | AppStorage = gadsStorage) {
    }

    /**
     * Store an item in the storage
     * @async
     * @param key The key of the item to store
     * @param value The value of the item to store
     */
    async setItem(key: string, value: string) {
        let item = await this.storage.getItem(this.instance);
        if (!item) item = '{}';
        const map: StringMap = fromJson(item);
        map[key] = value;
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }

    /**
     * Get an item value
     * @async
     * @param key The key of the item to get
     * @returns The value of the item stored under the key, or undefined if no value is stored
     */
    async getItem(key: string): Promise<string | undefined> {
        const item = await this.storage.getItem(this.instance);
        if (!item) return undefined;
        const map: StringMap = fromJson(item);
        return map[key] || undefined;
    }

    /**
     * Get all items stored in the storage
     * @async
     * @returns All items stored in the storage
     */
    async getAll(): Promise<StringMap> {
        const item = await this.storage.getItem(this.instance);
        if (!item) return {};
        return fromJson(item);
    }

    /**
     * Clear all items stored in the storage
     * @async
     */
    async clear() {
        this.storage.removeItem(this.instance);
    }

    /**
     * Remove an item from the storage
     * @async
     * @param key The key of the item to remove
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