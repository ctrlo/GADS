import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect, jest } from '@jest/globals';

import Footer from './Footer';
import { FooterProps } from './types';

import 'testing/extentions';

describe('Footer', () => {
    it('Creates a footer', () => {
        const footerProps: FooterProps = {
            addWidget: jest.fn(),
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard/1',
                download_url: 'http://localhost:3000/dashboard/1/download'
            },
            noDownload: false,
            readOnly: false,
            widgetTypes: ['type1', 'type2']
        };

        render(<Footer {...footerProps} />);

        expect(screen.getByText('Download')).toBeInstanceOf(HTMLButtonElement);
        // @ts-expect-error extension method
        expect(screen.getByText('As PDF')).toHaveAttribute('href', 'http://localhost:3000/dashboard/1/download');
        // @ts-expect-error extension method
        expect(screen.getByText('Add Widget')).toHaveNumberOfMenuItems(2);
        expect(screen.getByText('type1')).toBeInstanceOf(HTMLAnchorElement);
        expect(screen.getByText('type2')).toBeInstanceOf(HTMLAnchorElement);
    });

    it('Creates a footer without download', () => {
        const footerProps: FooterProps = {
            addWidget: jest.fn(),
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard/1',
                download_url: 'http://localhost:3000/dashboard/1/download'
            },
            noDownload: true,
            readOnly: false,
            widgetTypes: ['type1', 'type2']
        };

        render(<Footer {...footerProps} />);

        expect(screen.queryByText('Download')).toBeNull();
    });

    it('Creates a footer with read only', () => {
        const footerProps: FooterProps = {
            addWidget: jest.fn(),
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard/1',
                download_url: 'http://localhost:3000/dashboard/1/download'
            },
            noDownload: false,
            readOnly: true,
            widgetTypes: ['type1', 'type2']
        };

        render(<Footer {...footerProps} />);

        expect(screen.queryByText('Add Widget')).toBeNull();
    });

    it('Creates a footer with no download and read only', () => {
        const footerProps: FooterProps = {
            addWidget: jest.fn(),
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard/1',
                download_url: 'http://localhost:3000/dashboard/1/download'
            },
            noDownload: true,
            readOnly: true,
            widgetTypes: ['type1', 'type2']
        };

        render(<Footer {...footerProps} />);

        expect(screen.queryByText('Download')).toBeNull();
        expect(screen.queryByText('Add Widget')).toBeNull();
    });

    it('Clicks the create modal button with expected parameters', ()=>{
        const addWidget = jest.fn();
        const footerProps: FooterProps = {
            addWidget,
            currentDashboard: {
                name: 'Dashboard 1',
                url: 'http://localhost:3000/dashboard/1',
                download_url: 'http://localhost:3000/dashboard/1/download'
            },
            noDownload: false,
            readOnly: false,
            widgetTypes: ['type1', 'type2']
        };

        render(<Footer {...footerProps} />);

        const addWidgetButton = screen.getByText('type1');
        addWidgetButton.click();

        expect(addWidget).toHaveBeenCalledTimes(1);
        expect(addWidget).toHaveBeenCalledWith('type1');
        addWidget.mockClear();

        const addWidgetButton2 = screen.getByText('type2');
        addWidgetButton2.click();

        expect(addWidget).toHaveBeenCalledTimes(1);
        expect(addWidget).toHaveBeenCalledWith('type2');
    });
});