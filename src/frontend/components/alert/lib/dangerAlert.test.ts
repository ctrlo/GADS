import { describe, it, expect } from '@jest/globals';
import { DangerAlert } from './dangerAlert';

describe('Error Alert Tests', () => {
    it('should display an error alert with the correct message', () => {
        const errorMessage = 'This is a test error message';
        const errorAlert = new DangerAlert(errorMessage);

        const alert = errorAlert.render();
        
        document.body.appendChild(alert);

        expect(alert.classList.contains('alert-danger')).toBeTruthy();
        expect(alert.textContent).toContain(errorMessage);

        document.body.removeChild(alert);
    });
});
