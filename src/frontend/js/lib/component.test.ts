import '../../testing/globals.definitions';
import {describe, it, expect} from '@jest/globals';
import {Component, initializeComponent} from './component';

class BasicComponent extends Component {
    elementAsJQuery = $(this.element);

    constructor(element: HTMLElement) {
        super(element);
        this.init();
    }

    init() {
        this.element.innerText = 'This is a simple component!';
    }
}

describe('Component base class tests', () => {
    it('Can create a basic Component', ()=>{
        const div = document.createElement('div');
        const span = document.createElement('span')
        span.classList.add('test');
        span.innerText = 'Hello, World!';
        div.appendChild(span);
        const result =  initializeComponent(div, '.test', BasicComponent);
        expect(result.length).toBe(1);
        expect(result[0].element).toBe(span);
        expect(result[0] instanceof BasicComponent).toBe(true);
        expect(result[0].element.innerText).toBe('This is a simple component!');
        expect(result[0].elementAsJQuery.data("component-initialized-BasicComponent")).toBe("true");
    });
});
