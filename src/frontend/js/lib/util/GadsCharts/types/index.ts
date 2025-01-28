import { ChartConfiguration, ChartConfigurationCustomTypesPerDataset } from "chart.js";

export type ChartMap = {
    bar: BarChartConfig;
    doughnut: DoughnutChartConfig;
    donut: DoughnutChartConfig;
    line: LineChartConfig;
    pie: PieChartConfig;
}

export type ElementData = {
    ChartId: number;
    GraphType: keyof ChartMap;
    StackSeries: boolean;
    ShowLegend: boolean;
    GraphId: number;
    LayoutId: string;
    XAxisName?: string;
    YAxisLabel?: string;
}

export type LabelDefinition = {
    markeroptions: { show?: boolean };
    showlabel: boolean;
    color: string;
    label: string;
    showline: boolean;
}

export type BasicData = {
    xlabels: string[];
    labels: LabelDefinition[];
    points: PointData[][];
    options: object;
}

export type PointData = [string | number, string | number] | number;

export type GadsChart<T extends keyof ChartMap> = ChartMap[T];

export type ChartConfig<T extends keyof ChartMap> = T extends 'bar' ? BarChartConfig : T extends 'doughnut' ? DoughnutChartConfig : T extends 'line' ? LineChartConfig : T extends 'pie' ? PieChartConfig : never;
export type BarChartConfig = ChartConfiguration<'bar', (number | [number, number])[]> | ChartConfigurationCustomTypesPerDataset<'bar', (number | [number, number])[]>;
export type DoughnutChartConfig = ChartConfiguration<'doughnut', number[]> | ChartConfigurationCustomTypesPerDataset<'doughnut', number[]>;
export type LineChartConfig = ChartConfiguration<'line', (number | [number, number])[]> | ChartConfigurationCustomTypesPerDataset<'line', (number | [number, number])[]>;
export type PieChartConfig = ChartConfiguration<'pie', number[]> | ChartConfigurationCustomTypesPerDataset<'pie', number[]>;
