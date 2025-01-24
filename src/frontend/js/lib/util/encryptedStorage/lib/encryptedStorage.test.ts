import { setupCrypto } from 'testing/globals.definitions';
import { EncryptedStorage } from './encryptedStorage';
import {describe, expect, beforeAll, beforeEach, afterEach, it} from "@jest/globals";

class TestStorage implements Storage {
    private map = new Map<string, string>();

    [name: string]: any;
    length: number;

    clear(): void {
        this.map.clear();
        this.length = 0;
    }
    getItem(key: string): string | null {
        const ret = this.map.get(key);
        if (ret === undefined) {
            return null;
        }
        return ret;
    }
    key(index: number): string | null {
        const keys = Array.from(this.map.keys());
        if (keys.length <= index) {
            return null;
        }
        return keys[index];
    }
    removeItem(key: string): void {
        if (this.map.has(key)) {
            this.map.delete(key);
            this.length = this.map.size;
            this[key] = undefined;
        }
    }
    setItem(key: string, value: string): void {
        this.map.set(key, value);
        this[key] = value;
        this.length = this.map.size;
    }
}

describe('EncryptedStorage', () => {
    let encryptedStorageMock: EncryptedStorage;

    beforeAll(() => {
        // @ts-expect-error This is a unit test, so this is not readonly
        window.crypto && window.crypto.subtle && delete window.crypto.subtle; // We want to make sure the mock implementation of crypto is used
    })

    beforeEach(() => {
        setupCrypto();
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        encryptedStorageMock = new EncryptedStorage((data: string, key: string) => Promise.resolve(data), (data: string, key: string) => Promise.resolve(data), new TestStorage());
    });

    afterEach(() => {
        // @ts-expect-error This is a unit test, so this is not readonly
        window.crypto && window.crypto.subtle && delete window.crypto.subtle; // We want to also clear the mock implementation of crypto
    });

    it('should set and get an item', async () => {
        const key = 'key';
        const value = 'value';
        const encryptionKey = 'encryptionKey';
        await encryptedStorageMock.setItem(key, value, encryptionKey);
        const result = await encryptedStorageMock.getItem(key, encryptionKey);
        expect(result).toBe(value);
    });

    it('should remove an item', async () => {
        const key = 'key';
        const value = 'value';
        const encryptionKey = 'encryptionKey';
        await encryptedStorageMock.setItem(key, value, encryptionKey);
        encryptedStorageMock.removeItem(key);
        const result = await encryptedStorageMock.getItem(key, encryptionKey);
        expect(result).toBe(null);
    });

    it('should clear all items', async () => {
        const key = 'key';
        const value = 'value';
        const encryptionKey = 'encryptionKey';
        await encryptedStorageMock.setItem(key, value, encryptionKey);
        encryptedStorageMock.clear();
        const result = await encryptedStorageMock.getItem(key, encryptionKey);
        expect(result).toBe(null);
        expect(encryptedStorageMock.length).toBe(0);
    });

    it('should get length', async () => {
        const testStorage = new TestStorage();
        if (!testStorage.key) throw new Error('key is not defined');
        const key = 'key';
        const value = 'value';
        const encryptionKey = 'encryptionKey';
        await encryptedStorageMock.setItem(key, value, encryptionKey);
        expect(encryptedStorageMock.length).toBe(1);
    });
});
