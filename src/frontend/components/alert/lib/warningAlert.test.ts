import { describe, it, expect } from '@jest/globals';
import { WarningAlert } from './warningAlert';

describe('Warning Alert Tests', () => {
    it('should create a warning alert', () => {
        const message = 'This is a warning message';
        const alert = new WarningAlert(message);

        const result = alert.render();

        document.body.appendChild(result);

        expect(result.classList.contains('alert-warning')).toBe(true);
        expect(result.textContent).toBe(message);

        document.body.removeChild(result);
    });
});
