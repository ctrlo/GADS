import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect, jest } from '@jest/globals';

import Header from './Header';
import { HeaderProps } from './types';

describe('Header', () => {
    it('Creates a header', () => {
        const headerProps: HeaderProps = {
            hMargin: 0,
            dashboards: [
                {
                    name: 'Dashboard 1',
                    url: 'http://localhost:3000/dashboard/1'
                },
                {
                    name: 'Dashboard 2',
                    url: 'http://localhost:3000/dashboard/2'
                }
            ],
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard/1'
            },
            includeH1: true
        }

        const rendered = render(
            <Header {...headerProps} />
        );

        expect(screen.getByText('Dashboard 1').parentElement).toBeInstanceOf(HTMLHeadingElement);
        expect(screen.getByText('Dashboard 2').parentElement).toBeInstanceOf(HTMLAnchorElement);
    });
});
