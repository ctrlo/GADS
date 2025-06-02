import { describe, it, expect } from '@jest/globals';
import { FilterConfig } from './filterConfig';

describe('FieldFilterSetup', () => {  
  it('should initialize with empty fields and no search term', () => {
    const setup = new FilterConfig();
    expect(setup.fields).toEqual([]);
    expect(setup.searchTerm).toBeUndefined();
  });

  it('should filter fields based on search term', () => {
    const setup = new FilterConfig();
    setup.fields = [
      { id: 1, label: 'Field One', checked: false },
      { id: 2, label: 'Field Two', checked: false },
      { id: 3, label: 'Another Field', checked: false }
    ];
    setup.searchTerm = 'One';
    expect(setup.filteredFields).toEqual([{ id: 1, label: 'Field One', checked: false }]);
  });

  it('should return selected fields', () => {
    const setup = new FilterConfig();
    setup.fields = [
      { id: 1, label: 'Field One', checked: true },
      { id: 2, label: 'Field Two', checked: false },
      { id: 3, label: 'Another Field', checked: true }
    ];
    expect(setup.selectedFields).toEqual([
      { id: 1, label: 'Field One', checked: true },
      { id: 3, label: 'Another Field', checked: true }
    ]);
  });

  it('should return available fields', () => {
    const setup = new FilterConfig();
    setup.fields = [
      { id: 1, label: 'Field One', checked: true },
      { id: 2, label: 'Field Two', checked: false },
      { id: 3, label: 'Another Field', checked: false }
    ];
    expect(setup.availableFields).toEqual([
      { id: 2, label: 'Field Two', checked: false },
      { id: 3, label: 'Another Field', checked: false }
    ]);
  });

  it('should return all fields if no search term is set', () => {
    const setup = new FilterConfig();
    setup.fields = [
      { id: 1, label: 'Field One', checked: false },
      { id: 2, label: 'Field Two', checked: false }
    ];
    setup.searchTerm = undefined;
    expect(setup.filteredFields).toEqual(setup.availableFields);
  });

  it('should return all fields if search term is empty', () => {
    const setup = new FilterConfig();
    setup.fields = [
      { id: 1, label: 'Field One', checked: false },
      { id: 2, label: 'Field Two', checked: false }
    ];
    setup.searchTerm = '';
    expect(setup.filteredFields).toEqual([
      { id: 1, label: 'Field One', checked: false },
      { id: 2, label: 'Field Two', checked: false }
    ]);
  });
});