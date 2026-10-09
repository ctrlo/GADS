import { describe, it, expect } from '@jest/globals';
import { SuccessAlert } from './successAlert';

describe('Success Alert Tests', () => {
    it('should create a success alert', () => {
        const message = 'Operation completed successfully';
        const alert = new SuccessAlert(message);

        const result = alert.render();

        document.body.appendChild(result);

        expect(result.classList.contains('alert-success')).toBeTruthy();
        expect(result.textContent).toBe(message);

        document.body.removeChild(result);
    });
});
