import { Ref } from "react";
import ApiClient from "../api";
import ReactGridLayout from "react-grid-layout";

export interface DashboardDefinition {
    name?: string;
    url?: string;
}

export interface HeaderProps {
    hMargin: number;
    dashboards: DashboardDefinition[];
    currentDashboard: DashboardDefinition;
    loading: boolean;
    includeH1: boolean;
}

export interface WidgetState {
    key: string;
    onEditClick: (i: any) => (event: React.MouseEvent) => void;
    html: string | TrustedHTML;
    readOnly: boolean;
    config: ReactGridLayout.Layout;
}

export interface WidgetData {
    config: ReactGridLayout.Layout
    html: React.ReactHTML | string
}

export interface DashboardDefinition {
    id?: number,
    name?: string,
    url?: string,
    download_url?: string,
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
    widgets: WidgetData[];
    hideMenu: boolean;
    dashboardId: number;
}

export interface DashboardState {
    formRef: Ref<HTMLDivElement>;
    onEditClick: (id: string) => (event: React.MouseEvent) => void;
    config: ReactGridLayout.CoreProps;
    layoutChange: (layout: ReactGridLayout.Layout[]) => void;
    widgets: WidgetData[];
    saveActiveWidget: (event: React.MouseEvent) => void;
    deleteActiveWidget: () => void;
    editHtml: string;
    loadingEditHtml: boolean;
    editError: string;
    closeModal: () => void;
    modalOpen: boolean;
    readOnly: boolean;
}