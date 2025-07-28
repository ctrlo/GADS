import { describe, it, expect } from '@jest/globals';
import { Progress } from './Progress';

describe('Progress', () => {
  it('should initialize with default values', () => {
    const progress = new Progress(document.body, 'test-progress', 100);
    expect(progress.value).toBe(0);
  });

  it('should update progress correctly', () => {
    const progress = new Progress(document.body, 'test-progress', 100);
    progress.value=50;
    expect(progress.value).toBe(50);
  });

  it('should complete progress correctly', () => {
    const progress = new Progress(document.body, 'test-progress', 100);
    progress.value=100;
    expect(progress.value).toBe(100);
  });

  it('should handle invalid updates gracefully', () => {
    const progress = new Progress(document.body, 'test-progress', 100);
    progress.value=-10;
    expect(progress.value).toBe(0); // Should not go below 0
    progress.value=150;
    expect(progress.value).toBe(100); // Should not exceed total
  });
});