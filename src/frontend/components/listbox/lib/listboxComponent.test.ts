import { describe, it, expect } from '@jest/globals';
import ListComponent from './listboxComponent.ts';

describe('ListComponent', () => {
  it('Should create a list component', () => {
    const list = new ListComponent(document.createElement('div'));
    expect(list).toBeInstanceOf(ListComponent);
  });

  it('should add an item to the list', ()=>{
    const div = document.createElement('div');
    const content = document.createElement('div');
    content.classList.add('listbox-content');
    div.appendChild(content);
    const list = new ListComponent(div);
    list.addItem('Item 1', 1, document.createElement('input'));
    expect(div.querySelector('.listbox-item')).toBeTruthy();
  });

  it('should remove an item from the list', ()=>{
    const div = document.createElement('div');
    const content = document.createElement('div');
    content.classList.add('listbox-content');
    div.appendChild(content);
    const list = new ListComponent(div);
    list.addItem('Item 1', 1, document.createElement('input'));
    list.addItem('Item 2', 2, document.createElement('input'));
    list.removeItem('Item 1');
    expect(div.querySelector('.listbox-item')).toBeTruthy();
    expect(div.querySelector('.listbox-item')?.textContent || 'FAIL').toBe('Item 2');
  });

  it('should respect order when rendering items', ()=>{
    const div = document.createElement('div');
    const content = document.createElement('div');
    content.classList.add('listbox-content');
    div.appendChild(content);
    const list = new ListComponent(div);
    list.addItem('Item 2', 2, document.createElement('input'));
    list.addItem('Item 1', 1, document.createElement('input'));
    list.addItem('Item 3', 3, document.createElement('input'));
    const items = div.querySelectorAll('.listbox-item');
    expect(items[0].textContent).toBe('Item 1');
    expect(items[1].textContent).toBe('Item 2');
    expect(items[2].textContent).toBe('Item 3');
  })
});