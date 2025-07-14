import "testing/globals.definitions";
import { describe, it, expect, jest } from "@jest/globals";
import { AppStorage } from "./AppStorage";
import { GadsStorage } from "./GadsStorage";
import { NullStorage } from "./NullStorage";
import { setupCrypto } from "testing/globals.definitions";

describe("AppStorage", () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    it("Should create a GADS storage instance", () => {
        setupCrypto();
        const storage = AppStorage.CreateStorageInstance();
        expect(storage).toBeInstanceOf(GadsStorage);
    });

    it("Should create a null storage instance", () => {
        // @ts-expect-error This is a unit test, so this is not readonly
        delete window.crypto.subtle;
        const storage = AppStorage.CreateStorageInstance();
        expect(storage).toBeInstanceOf(NullStorage);
    });
});