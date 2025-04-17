import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { addRow, clearTable, updateRow } from './helper';
import Datatable from 'datatables.net-bs5';

describe('helper', () => {
    beforeEach(() => {
        document.body.innerHTML = `
        <table id="target" class="table table-striped">
            <thead>
                <tr>
                    <th>Forename</th>
                    <th>Surname</th>
                    <th>Age</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>John</td>
                    <td>Doe</td>
                    <td>30</td>
                    <td>
                        <button class="btn btn-danger btn-sm" data-tempid="beep"></button>
                    </td>
                </tr>
            </tbody>
        </table>
        `
    });

    afterEach(() => {
        document.body.innerHTML = '';
    })

    it('should add a row to a datatable', () => {
        const target = document.getElementById('target');
        expect(target).not.toBeNull();
        new Datatable(target as HTMLElement);
        expect(Datatable.isDataTable(target as HTMLElement)).toBeTruthy();
        expect(target?.querySelectorAll('tbody tr').length).toBe(1);
        addRow(['Daddy', 'Cool', '40'], $(target as HTMLElement));
        expect(target?.querySelectorAll('tbody tr').length).toBe(2);
    });

    it('should update a row', () => {
        const target = document.getElementById('target');
        if (!target) throw new Error('Target not found');
        new Datatable(target);
        expect(Datatable.isDataTable(target)).toBeTruthy();
        expect(target.querySelectorAll('tbody tr').length).toBe(1);
        let rows = target.querySelectorAll('tbody tr');
        expect(rows[0].querySelectorAll('td')[0].textContent).toBe('John');
        expect(rows[0].querySelectorAll('td')[1].textContent).toBe('Doe');
        expect(rows[0].querySelectorAll('td')[2].textContent).toBe('30');
        updateRow(['Johan', 'Smith', '31'], $(target), 'beep');
        rows = target.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].querySelectorAll('td')[0].textContent).toBe('Johan');
        expect(rows[0].querySelectorAll('td')[1].textContent).toBe('Smith');
        expect(rows[0].querySelectorAll('td')[2].textContent).toBe('31');
    });

    it('Should clear a table', () => {
        const target = document.getElementById('target');
        if (!target) throw new Error('Target not found');
        new Datatable(target);
        expect(Datatable.isDataTable(target)).toBeTruthy();
        expect(target.querySelectorAll('tbody tr').length).toBe(1);
        addRow(['Daddy', 'Cool', '40'], $(target));
        expect(target.querySelectorAll('tbody tr').length).toBe(2);
        clearTable($(target));
        expect(target.querySelectorAll('tbody tr').length).toBe(1);
    });
});