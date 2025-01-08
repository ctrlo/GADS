import "../../../../../testing/globals.definitions";
import { describe, it, expect, beforeAll, beforeEach, afterEach } from "@jest/globals";
import { GadsStorage } from "./GadsStorage";
import { setupCrypto } from "../../../../../testing/globals.definitions";

if (!process.versions.node.startsWith("18")) {
    describe("GadsStorage", () => {
        const header = () => {
            const ivArray = Array.from(new Uint8Array(12));
            const result = ivArray;
            return btoa(JSON.stringify(result));
        }

        beforeAll(() => {
            // @ts-expect-error This is a unit test, so this is not readonly
            window.crypto && window.crypto.subtle && delete window.crypto.subtle; // We want to make sure the mock implementation of crypto is used
        })

        beforeEach(() => {
            setupCrypto();
        });

        afterEach(() => {
            // @ts-expect-error This is a unit test, so this is not readonly
            window.crypto && window.crypto.subtle && delete window.crypto.subtle; // We want to also clear the mock implementation of crypto
        });

        it("Should set an item", async () => {
            const storage = new GadsStorage();
            const key = "key";
            const value = "value";
            await storage.setItem(key, value);
            const result = localStorage.getItem(key);
            expect(result).not.toBeFalsy();
            expect(crypto.subtle.encrypt).toHaveBeenCalled();
            expect(result).toBe(header()); // As the function is a null function, we'll only really get the header back
        });

        it("Should get an item", async () => {
            const storage = new GadsStorage();
            const key = "key";
            const value = "value";
            await storage.setItem(key, value);
            const result = await storage.getItem(key);
            expect(crypto.subtle.decrypt).toHaveBeenCalled();
            expect(result).toBe("value");
        });

        it("Should remove an item", async () => {
            const storage = new GadsStorage();
            const key = "key";
            const value = "value";
            await storage.setItem(key, value);
            storage.removeItem(key);
            const result = localStorage.getItem(key);
            expect(result).toBeFalsy();
        });

        it("Should clear all items", async () => {
            const storage = new GadsStorage();
            const key = "key";
            const value = "value";
            await storage.setItem(key, value);
            storage.clear();
            const result = localStorage.getItem(key);
            expect(result).toBeFalsy();
        });

        it("Should get the length", async () => {
            const storage = new GadsStorage();
            const key = "key";
            const value = "value";
            await storage.setItem(key, value);
            expect(storage.length).toBe(1);
            storage.clear();
            expect(storage.length).toBe(0);
        });
    });
} else {
    console.warn("GadsStorage tests are skipped because they are not compatible with Node 18");
    describe.skip("GadsStorage", () => {
        it("Should skip", () => {});
    })
}
