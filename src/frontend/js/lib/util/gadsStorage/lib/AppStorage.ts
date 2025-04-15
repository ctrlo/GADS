import { GadsStorage } from "./GadsStorage";
import { NullStorage } from "./NullStorage";

/**
 * Interface for a storage object that can be used to store data in the browser.
 */
export abstract class AppStorage {
    static CreateStorageInstance(): AppStorage {
        return crypto.subtle && typeof crypto.subtle != "undefined" ? new GadsStorage() : new NullStorage();
    }
    /**
     * Store a value in the browsers' storage
     * @param key The key to store the value under
     * @param value The value to store
     */
    abstract setItem(key: string, value: string): Promise<void>;
    /**
     * Retrieve a value from the browsers' storage
     * @param key The key to retrieve the value for
     * @returns The value stored under the key, or null if no value is stored
     */
    abstract getItem(key: string): Promise<string | null>;
    /**
     * Remove a value from the browsers' storage. This is idempotent.
     * @param key The key to remove the value for
     */
    abstract removeItem(key: string): void;
    /**
     * Clear all values from the browsers' storage
     */
    abstract clear(): void;
    /**
     * Retrieve the key at the given index in the browsers' storage
     * @param index The index of the key to retrieve
     * @returns The key at the given index, or null if the index is out of bounds
     */
    abstract key(index: number): string | null;
    /**
     * The number of items stored in the browsers' storage
     */
    abstract readonly length: number;

    abstract readonly enabled: boolean;
}
