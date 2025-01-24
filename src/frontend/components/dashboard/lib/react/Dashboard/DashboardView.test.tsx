import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect, jest } from '@jest/globals';

import DashboardView from './DashboardView';
import { WidgetProps } from '../types';
import { ReactGridLayoutProps } from 'react-grid-layout';

describe('DashboardView', () => {
    it('Creates a dashboard', () => {
        const gridConfig:ReactGridLayoutProps = {
            cols: 2,
            margin: [32, 32],
            containerPadding: [0, 10],
            rowHeight: 80,
        }

        const widgets:WidgetProps[] = [
            {
                config:{
                    h: 1,
                    i: "0",
                    w: 1,
                    x: 0,
                    y: 0,
                },
                html: '<div data-testid="widget1">Widget 1</div>'
            }
        ];

        const props = {
            readOnly: false,
            gridConfig,
            layout: widgets.map(w => w.config),
            onEditClick: jest.fn(),
            onLayoutChange: jest.fn(),
            widgets,
        }
        render(<DashboardView {...props} />);

        expect(screen.getByTestId('widget1')).toBeInstanceOf(HTMLDivElement);
        expect(screen.getByTestId('widget1').textContent).toBe('Widget 1');
    });

    it('should trigger event on edit button click', () => {
        const gridConfig:ReactGridLayoutProps = {
            cols: 2,
            margin: [32, 32],
            containerPadding: [0, 10],
            rowHeight: 80,
        }

        const widgets:WidgetProps[] = [
            {
                config:{
                    h: 1,
                    i: "0",
                    w: 1,
                    x: 0,
                    y: 0,
                },
                html: '<div data-testid="widget1">Widget 1</div>'
            }
        ];

        const props = {
            readOnly: false,
            gridConfig,
            layout: widgets.map(w => w.config),
            onEditClick: jest.fn(),
            onLayoutChange: jest.fn(),
            widgets,
        }
        render(<DashboardView {...props} />);

        const editButton = screen.getByTestId('edit');
        expect(editButton).toBeInstanceOf(HTMLAnchorElement);
        editButton.click();
        expect(props.onEditClick).toHaveBeenCalledWith("0");
    });
});