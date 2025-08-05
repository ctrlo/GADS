import ReactGridLayout, { Layout } from 'react-grid-layout';
import ApiClient from '../api';
import { RefObject } from 'react';

/**
 * Basic function type for callbacks
 */
type BasicFunction = (...params: any[]) => any;

/**
 * Header component properties
 */
export type HeaderProps = {
    /**
     * The horizontal margin for the layout, used to calculate the width of the dashboard
     * @type {number}
     */
    hMargin: number;
    /**
     * The different dashboards available
     * @type {DashboardProps[]}
     */
    dashboards: DashboardProps[];
    /**
     * The currently selected dashboard
     * @type {DashboardProps}
     */
    currentDashboard: DashboardProps;
    /**
     * Whether to include an H1 tag in the header
     * @type {boolean}
     */
    includeH1: boolean;
};

/**
 * Dashboard component properties
 */
export type DashboardProps = {
    /**
     * The name of the dashboard
     * @type {string}
     */
    name: string;
    /**
     * The URL of the dashboard
     * @type {string}
     */
    url: string;
    /**
     * The download URL for the dashboard
     * @type {string}
     */
    download_url?: string;
};

/**
 * Footer component properties
 */
export type FooterProps = {
    /**
     * Add a new widget to the dashboard
     * @param type The type of widget to add
     * @type {(type: string) => void}
     */
    addWidget: (type: string) => void;
    /**
     * The different widget types available
     * @type {string[]}
     */
    widgetTypes: string[];
    /**
     * The currently selected dashboard
     * @type {DashboardProps}
     */
    currentDashboard: DashboardProps;
    /**
     * Whether the dashboard is read-only
     * @type {boolean}
     */
    readOnly: boolean;
    /**
     * Whether to disable the download button
     * @type {boolean}
     */
    noDownload: boolean;
};

/**
 * Widget component properties
 */
export type WidgetProps = {
    /**
     * The HTML content of the widget
     * @type {string}
     */
    html: string;
    /**
     * The widget configuration
     * @type {Layout}
     */
    config: Layout;
};

/**
 * Application properties
 */
export type AppProps = {
    /**
     * Whether to hide the menu
     * @type {boolean}
     */
    hideMenu: boolean;
    /**
     * The grid configuration for the dashboard
     * @type {ReactGridLayout.ReactGridLayoutProps}
     */
    gridConfig: ReactGridLayout.ReactGridLayoutProps;
    /**
     * The dashboards available in the application
     * @type {DashboardProps[]}
     */
    dashboards: DashboardProps[];
    /**
     * The currently selected dashboard
     * @type {DashboardProps}
     */
    currentDashboard: DashboardProps;
    /**
     * Whether to include an H1 tag in the header
     * @type {boolean}
     */
    includeH1: boolean;
    /**
     * Whether the dashboard is read-only
     * @type {boolean}
     */
    readOnly: boolean;
    /**
     * The different widget types available
     * @type {string[]}
     */
    widgetTypes: string[];
    /**
     * Whether to disable the download button
     * @type {boolean}
     */
    noDownload: boolean;
    /**
     * The widgets to display on the dashboard
     * @type {WidgetProps[]}
     */
    widgets: WidgetProps[];
    /**
     * The ID of the current dashboard
     * @type {string}
     */
    dashboardId: string;
    /**
     * The API client for making requests
     * @type {ApiClient}
     */
    api: ApiClient;
};

/**
 * Properties for the EditModal component
 */
export type AppModalProps = {
    /**
     * Function to close the modal
     * @type {() => void}
     */
    closeModal: () => void,
    /**
     * Reference to the form element
     * @type {RefObject<HTMLDivElement>}
     */
    formRef: RefObject<HTMLDivElement>,
    /**
     * Function to delete the active widget
     * @type {() => void}
     */
    deleteActiveWidget: () => void,
    /**
     * Function to save the active widget
     * @type {(event: any) => void}
     */
    saveActiveWidget: (event: any) => void,
    /**
     * Whether the edit modal is open
     * @type {boolean}
     */
    editModalOpen: boolean,
    /**
     * Error message for editing the widget
     * @type {string|null}
     */
    editError: string | null,
    /**
     * Whether the edit HTML is loading
     * @type {boolean}
     */
    loadingEditHtml: boolean,
    /**
     * HTML content for editing the widget
     * @type {string|null}
     */
    editHtml: string | null
};

/**
 * Properties for an individual dashboard widget
 */
export type DashboardViewProps = {
    /**
     * Whether the dashboard is read-only
     * @type {boolean}
     */
    readOnly: boolean;
    /**
     * The layout configuration for the dashboard
     * @type {Layout}
     */
    layout: Layout[],
    /**
     * Callback function for when the layout changes
     * @type {BasicFunction}
     */
    onLayoutChange: BasicFunction,
    /**
     * Configuration for the grid layout
     * @type {object}
     */
    gridConfig: object,
    /**
     * The widgets to display on the dashboard
     * @type {WidgetProps[]}
     */
    widgets: WidgetProps[],
    /**
     * Callback function for when the edit button is clicked
     * @type {BasicFunction}
     */
    onEditClick: BasicFunction
};

/**
 * Properties for the MenuItem component
 */
export type MenuProps = {
    /**
     * The dashboard to display in the menu item
     * @type {DashboardProps}
     */
    dashboard: DashboardProps,
    /**
     * The currently selected dashboard
     * @type {DashboardProps}
     */
    currentDashboard: DashboardProps,
    /**
     * Whether to include an H1 tag in the menu item
     * @type {boolean}
     */
    includeH1: boolean
};

/**
 * Properties for the widget view component
 */
export type WidgetViewProps = {
    /**
     * The HTML content of the widget
     * @type {string}
     */
    html: string,
    /**
     * Whether the widget is read-only
     * @type {boolean}
     */
    readOnly: boolean,
    /**
     * Callback function for when the edit button is clicked
     * @type {BasicFunction}
     */
    onEditClick: BasicFunction
};

/**
 * JSON Response type for the dashboard API
 */
export type ApiResponse = {
    /**
     * Whether the API call is an error
     * @type {number|boolean}
     */
    error?: number|boolean;
    /**
     * Whether the API call is an error
     * @type {number|boolean}
     */
    is_error?: number|boolean;
    /**
     * The error message, if any
     * @type {string}
     */
    message?: string;
    /**
     * The content of the API response
     * @type {string}
     */
    content?: string;
};
