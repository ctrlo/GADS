import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect } from '@jest/globals';

import Header from './Header';

describe('Header', () => {
    it('should render the header', () => {
        const props = {
            hMargin: 0,
            dashboards: [
                {
                    name: 'Dashboard 1',
                    url: 'http://localhost:3000/dashboard1'
                },
                {
                    name: 'Dashboard 2',
                    url: 'http://localhost:3000/dashboard2'
                }
            ],
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard1'
            },
            includeH1: true,
            loading: false
        };

        render(<Header {...props} />);

        expect(screen.getByText('Dashboard 1').parentElement).toBeInstanceOf(HTMLHeadingElement);
        expect(screen.getByText('Dashboard 2').parentElement).toBeInstanceOf(HTMLAnchorElement);
    });
});
