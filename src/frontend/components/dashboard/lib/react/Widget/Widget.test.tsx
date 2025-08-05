import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect, jest } from '@jest/globals';

import Widget from './Widget';
import { WidgetProps } from '../types';

describe('Widget', () => {
    const WidgetProps: WidgetProps = {
        config: {
            h: 1,
            i: '0',
            w: 1,
            x: 0,
            y: 0
        },
        html: '<div>Test</div>'
    };

    it('Renders a Widget with HTML set', () => {
        render(<Widget html={WidgetProps.html} onEditClick={jest.fn()} readOnly={false} />);

        expect(screen.getByText('Test')).toBeInstanceOf(HTMLDivElement);
        expect(screen.getByTestId('edit')).toBeInstanceOf(HTMLAnchorElement);
        expect(screen.getByTestId('drag')).toBeInstanceOf(HTMLSpanElement);
    });

    it('Renders a Readonly Widget', ()=>{
        render(<Widget html={WidgetProps.html} onEditClick={jest.fn()} readOnly={true} />);

        expect(screen.queryByTestId('edit')).toBeNull();
        expect(screen.queryByTestId('drag')).toBeNull();
    });

    it('Calls onEditClick when edit button is clicked', ()=>{
        const onEditClick = jest.fn();
        render(<Widget html={WidgetProps.html} onEditClick={onEditClick} readOnly={false} />);

        screen.getByTestId('edit').click();
        expect(onEditClick).toHaveBeenCalled();
    });
});
