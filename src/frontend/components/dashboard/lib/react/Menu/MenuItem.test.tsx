import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect } from '@jest/globals';

import MenuItem from './MenuItem';
import { DashboardProps } from '../types';

describe('MenuItem', () => {
    it('Renders a MenuItem with H1 set', () => {
        const DashboardProps: DashboardProps = {
            name: 'Dashboard 1',
            url: 'http://localhost:3000/dashboard',
            download_url: 'http://localhost:3000/dashboard/download',
        }

        render(<MenuItem dashboard={DashboardProps} currentDashboard={DashboardProps} includeH1={true} />);

        expect(screen.getByText('Dashboard 1').parentElement).toBeInstanceOf(HTMLHeadingElement);
    });

    it('Renders a MenuItem without H1 set', () => {
        const DashboardProps: DashboardProps = {
            name: 'Dashboard 1',
            url: 'http://localhost:3000/dashboard',
            download_url: 'http://localhost:3000/dashboard/download',
        }

        render(<MenuItem dashboard={DashboardProps} currentDashboard={DashboardProps} includeH1={false} />);

        expect(screen.getByText('Dashboard 1').parentElement).toBeInstanceOf(HTMLAnchorElement);
    });

    it('Renders a MenuItem with different currentDashboard', () => {
        const DashboardProps: DashboardProps[] = [{
            name: 'Dashboard 1',
            url: 'http://localhost:3000/dashboard',
            download_url: 'http://localhost:3000/dashboard/download',
        }, {
            name: 'Dashboard 2',
            url: 'http://localhost:3000/dashboard2',
            download_url: 'http://localhost:3000/dashboard2/download',
        }]

        render(<MenuItem dashboard={DashboardProps[0]} currentDashboard={DashboardProps[1]} includeH1={true} />);

        expect(screen.getByText('Dashboard 1').parentElement).toBeInstanceOf(HTMLAnchorElement);
    });
});