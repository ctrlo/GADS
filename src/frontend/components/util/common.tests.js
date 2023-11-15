describe('common functions', () => {
    it('stops propagation', () => {
        const ev = {
            stopPropagation: jest.fn(),
            preventDefault: jest.fn()
        };
        stopPropagation(ev);
        expect(ev.stopPropagation).toHaveBeenCalled();
        expect(ev.preventDefault).toHaveBeenCalled();
    });
});
