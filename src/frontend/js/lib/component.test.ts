import "../../testing/globals.definitions";
import { it, expect, describe } from '@jest/globals';
import { Component, initializeComponent } from './component';

class TestComponent extends Component {
    constructor(element: HTMLElement) {
        super(element);
        element.innerText = 'I have this text now!';
    }
}

function testComponentInitializer(scope: HTMLElement) {
    return initializeComponent(scope, '.test-component', TestComponent);
}

describe('Component Tests', ()=>{
    it('should be created', ()=>{
        const div = document.createElement('div');
        const span = document.createElement('span');
        span.classList.add('test-component');
        span.innerText = 'I shouldn\'t have this text when initialized';
        div.appendChild(span);
        document.body.appendChild(div);
        const component = testComponentInitializer(document.body);
        expect(component.length).toBe(1);
        expect(component[0]).toBeInstanceOf(TestComponent);
        expect(component[0].element.innerText).toBe('I have this text now!');
    });
});

