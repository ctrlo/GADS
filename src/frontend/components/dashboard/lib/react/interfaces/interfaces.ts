import ApiClient from "../api";
import ReactGridLayout from "react-grid-layout";

export interface Widget {
    config: ReactGridLayout.Layout
    html: React.ReactHTML | string
}

export interface DashboardDefinition {
    id?: number,
    name?:string,
    url?:string,
    download_url?:string,
};

export interface FooterState {
    addWidget: (type: string) => void;
    widgetTypes: string[];
    currentDashboard: any;
    readOnly: boolean;
    noDownload: boolean;
}

export interface AppState {
    readOnly: boolean;
    noDownload: boolean;
    widgetTypes: string[];
    dashboards: DashboardDefinition[];
    currentDashboard: DashboardDefinition;
    api: ApiClient;
    widgets: Widget[];
    hideMenu: boolean;
    dashboardId: number;
}

export interface DashboardState {
    config: ReactGridLayout.CoreProps;
    layoutChange: (layout: ReactGridLayout.Layout[]) => void;
    widgets: Widget[];
    saveActiveWidget: (event: React.MouseEvent) => void;
    deleteActiveWidget: () => void;
    editHtml: string;
    loadingEditHtml: boolean;
    editError: string;
    closeModal: () => void;
    modalOpen: boolean;
    readOnly: boolean;
}