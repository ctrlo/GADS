import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/dom';
import { describe, it, expect, jest } from '@jest/globals';

import EditModal from './EditModal';
import {AppModalProps} from '../types';

describe('EditModal', () => {
    it('Creates a modal',()=>{
        const modalProps:AppModalProps = {
            closeModal:()=>{},
            deleteActiveWidget:()=>{},
            editError:'',
            editHtml:'',
            editModalOpen:true,
            formRef:React.createRef(),
            loadingEditHtml:true,
            saveActiveWidget:()=>{}
        };

        render(
            <div>
                <div className='ld-app' id='ld-app'></div>
                <EditModal {...modalProps} />
            </div>
        );

        expect(screen.getByText('Edit widget')).toBeInstanceOf(HTMLHeadingElement);
        expect(screen.getByText('Loading...')).toBeInstanceOf(HTMLSpanElement);
    });

    it('Creates a modal with the HTML content',()=>{
        const modalProps:AppModalProps = {
            closeModal:()=>{},
            deleteActiveWidget:()=>{},
            editError:'',
            editHtml:'<div>Test</div>',
            editModalOpen:true,
            formRef:React.createRef(),
            loadingEditHtml:false,
            saveActiveWidget:()=>{}
        };

        render(
            <div>
                <div className='ld-app' id='ld-app'></div>
                <EditModal {...modalProps} />
            </div>
        );

        expect(screen.getByText('Edit widget')).toBeInstanceOf(HTMLHeadingElement);
        expect(screen.getByText('Test')).toBeInstanceOf(HTMLDivElement);
    });

    it('Creates a modal with the error message',()=>{
        const modalProps:AppModalProps = {
            closeModal:()=>{},
            deleteActiveWidget:()=>{},
            editError:'Error',
            editHtml:'',
            editModalOpen:true,
            formRef:React.createRef(),
            loadingEditHtml:false,
            saveActiveWidget:()=>{}
        };

        render(
            <div>
                <div className='ld-app' id='ld-app'></div>
                <EditModal {...modalProps} />
            </div>
        );

        expect(screen.getByText('Edit widget')).toBeInstanceOf(HTMLHeadingElement);
        expect(screen.getByText('Error')).toBeInstanceOf(HTMLParagraphElement);
    });

    it('Fires the close event as expected', ()=>{
        const modalProps:AppModalProps = {
            closeModal:jest.fn(),
            deleteActiveWidget:jest.fn(),
            editError:'',
            editHtml:'',
            editModalOpen:true,
            formRef:React.createRef(),
            loadingEditHtml:true,
            saveActiveWidget:jest.fn()
        };

        render(
            <div>
                <div className='ld-app' id='ld-app'></div>
                <EditModal {...modalProps} />
            </div>
        );

        screen.getByText('Close').click();
        expect(modalProps.closeModal).toHaveBeenCalled();
    });

    it('Fires the delete event as expected', ()=>{
        const modalProps:AppModalProps = {
            closeModal:jest.fn(),
            deleteActiveWidget:jest.fn(),
            editError:'',
            editHtml:'',
            editModalOpen:true,
            formRef:React.createRef(),
            loadingEditHtml:true,
            saveActiveWidget:jest.fn()
        };

        render(
            <div>
                <div className='ld-app' id='ld-app'></div>
                <EditModal {...modalProps} />
            </div>
        );

        screen.getByText('Delete').click();
        expect(modalProps.deleteActiveWidget).toHaveBeenCalled();
    });

    it('Fires the save event as expected', ()=>{
        const modalProps:AppModalProps = {
            closeModal:jest.fn(),
            deleteActiveWidget:jest.fn(),
            editError:'',
            editHtml:'',
            editModalOpen:true,
            formRef:React.createRef(),
            loadingEditHtml:true,
            saveActiveWidget:jest.fn()
        };

        render(
            <div>
                <div className='ld-app' id='ld-app'></div>
                <EditModal {...modalProps} />
            </div>
        );

        screen.getByText('Save').click();
        expect(modalProps.saveActiveWidget).toHaveBeenCalled();
    });
});
