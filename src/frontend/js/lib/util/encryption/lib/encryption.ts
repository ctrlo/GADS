export async function encrypt(data: string, password: string): Promise<string> {
    const key = createKey(password, "encrypt");
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const encoder = new TextEncoder();
    const encoded = encoder.encode(data);
    const encrypted = crypto.subtle.encrypt(
        {
            name: "AES-GCM",
            iv: iv
        },
        await key,
        encoded
    );
    const ivArray = Array.from(iv);
    const encryptedArray = Array.from(new Uint8Array(await encrypted));
    const result = ivArray.concat(encryptedArray);
    return btoa(JSON.stringify(result));
}

export async function decrypt(data: string, password: string): Promise<string> {
    const key = createKey(password, "decrypt");
    const decoded = JSON.parse(atob(data));
    const iv = new Uint8Array(decoded.slice(0, 12));
    const encrypted = new Uint8Array(decoded.slice(12));
    const decrypted = crypto.subtle.decrypt(
        {
            name: "AES-GCM",
            iv: iv
        },
        await key,
        encrypted
    );
    const decoder = new TextDecoder();
    return decoder.decode(await decrypted);
}


async function createKey(password: string, mode: "encrypt" | "decrypt") {
    const salt = new TextEncoder().encode("salt");
    const encoder = new TextEncoder();
    const deriver = crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveKey"]);
    const key = crypto.subtle.deriveKey(
        {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256"
        },
        await deriver,
        { name: "AES-GCM", length: 256 },
        true,
        [mode]
    );
    return await key;
}
