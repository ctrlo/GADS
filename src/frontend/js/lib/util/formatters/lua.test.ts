import { LUA } from "./lua";
import {describe, it, expect} from "@jest/globals";

describe("LUA tests", ()=>{
    class TestObject {
        toString(){
            return "test";
        }
    }

    it("Should return empty string", ()=>{
        expect(LUA``).toBe("");
    });

    it("Should return string with value", ()=>{
        expect(LUA`test`).toBe("test");
    });

    it("Should return string with value", ()=>{
        expect(LUA`test${1}`).toBe("test1");
    });

    it("Should return string with value", ()=>{
        expect(LUA`${1}test`).toBe("1test");
    });

    it("Should return string with value", ()=>{
        expect(LUA`${1}test${2}`).toBe("1test2");
    });

    it("Should return string with value", ()=>{
        expect(LUA`${1}test${2}test${3}`).toBe("1test2test3");
    });

    it("Should return string with value", ()=>{
        expect(LUA`${new TestObject()}`).toBe("test");        
    })
});