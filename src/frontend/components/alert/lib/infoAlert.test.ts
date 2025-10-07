import { describe, it, expect } from '@jest/globals';
import { InfoAlert } from './infoAlert';

describe('Info Alert Tests', () => {
    it('should display an info alert with the correct message', () => {
        const infoMessage = 'This is a test info message';
        const infoAlert = new InfoAlert(infoMessage);
        
        const alert = infoAlert.render();

        document.body.appendChild(alert);

        expect(alert.classList.contains('alert-info')).toBeTruthy();
        expect(alert.textContent).toContain(infoMessage);

        document.body.removeChild(alert);
    });
});
