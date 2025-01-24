import {jest, describe, it, expect, beforeAll, afterEach} from "@jest/globals";
import createRemoveCurvalButton from "./remove-curval-button";

describe("RemoveCurvalButton", ()=>{
    // @ts-ignore
    window.confirm = jest.fn().mockReturnValue(true);

    beforeAll(()=>{
        document.body.innerHTML = "";
    });

    afterEach(()=>{
        document.body.innerHTML = "";
    });

    it("should mock as expected", ()=>{
        expect(confirm("Are you sure you wish to continue?")).toBe(true);
    });

    it('Should remove a value from a table', ()=>{
        const table = document.createElement("table");
        table.className="table-curval-group";
        const tbody = document.createElement("tbody");
        const tr = document.createElement("tr");
        tr.className = "table-curval-item";
        const td = document.createElement("td");
        tr.appendChild(td);
        tbody.appendChild(tr);
        table.appendChild(tbody);
        document.body.appendChild(table);
        const td2 = document.createElement("td");
        const button = document.createElement("button");
        button.className = "remove-curval";
        td2.appendChild(button);
        tr.appendChild(td2);
        createRemoveCurvalButton($(button));
        button.click();
        expect(table.children[0].children.length).toBe(0);
    });

    it('Should remove a value from a select widget', ()=>{
        const selectWidget = document.createElement("div");
        selectWidget.className = "select-widget";
        const answer = document.createElement("div");
        answer.className = "answer";
        const input = document.createElement("input");
        input.id = "input";
        answer.appendChild(input);
        selectWidget.appendChild(answer);
        const current = document.createElement("div");
        current.className = "current";
        const li = document.createElement("li");
        li.dataset.listItem = "input";
        current.appendChild(li);
        selectWidget.appendChild(current);
        document.body.appendChild(selectWidget);
        const button = document.createElement("button");
        button.className = "remove-curval";
        answer.appendChild(button);
        createRemoveCurvalButton($(button));
        button.click();
        expect(current.children.length).toBe(0);
    });
});
