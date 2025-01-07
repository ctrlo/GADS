import ReactGridLayout, { Layout } from "react-grid-layout";
import ApiClient from "../api";

export type HeaderProps = {
    hMargin: number;
    dashboards: DashboardProps[];
    currentDashboard: DashboardProps;
    loading: boolean;
    includeH1: boolean;
}

export type DashboardProps = {
    name: string;
    url: string;
    download_url?: string;
}

export type FooterProps = {
    addWidget: (type: string) => void;
    widgetTypes: string[];
    currentDashboard: DashboardProps;
    readOnly: boolean;
    noDownload: boolean;
}

export type WidgetProps = {
    html: string;
    config: Layout;
}

export type AppProps = {
    hideMenu: boolean;
    gridConfig: ReactGridLayout.ReactGridLayoutProps;
    dashboards: DashboardProps[];
    currentDashboard: DashboardProps;
    includeH1: boolean;
    readOnly: boolean;
    widgetTypes: string[];
    noDownload: boolean;
    widgets: WidgetProps[];
    dashboardId: string;
    api: ApiClient;
}