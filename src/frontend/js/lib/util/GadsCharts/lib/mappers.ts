import { BarChartConfig, BasicData, ChartMap, DoughnutChartConfig, ElementData, GadsChart, LineChartConfig, PieChartConfig, PointData } from "../types";

export function getPointLabel(point: PointData): string {
    if (Array.isArray(point)) {
        for (const item of point)
            if (typeof item === 'string')
                return item;
        throw new Error('Invalid point data');
    } else {
        if (typeof point === 'string')
            return point;
        else
            throw new Error('Invalid point data');
    }
}

export function getPointValue(point: PointData): number {
    if (Array.isArray(point)) {
        for (const item of point)
            if (typeof item === 'number')
                return item;
        throw new Error('Invalid point data');
    } else {
        if (typeof point === 'number')
            return point;
        else
            throw new Error('Invalid point data');
    }
}

export function mapData<T extends keyof ChartMap>(elementData: ElementData, data: BasicData): GadsChart<T> {
    switch (elementData.GraphType) {
        case 'bar':
            {
                const result: BarChartConfig = {
                    type: 'bar',
                    data: {
                        datasets: [{
                            label: data.labels.map(label => label.label)[0],
                            data: data.points[0] as unknown as number[],
                            borderWidth: 1,
                            backgroundColor: data.labels.map(label => label.color)[0],
                        }],
                        xLabels: data.xlabels,
                    },
                    options: {
                        plugins: {
                            legend: {
                                display: elementData.ShowLegend,
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                }
                return result as GadsChart<T>;
            }
        case 'line':
            {
                const result: LineChartConfig = {
                    type: 'line',
                    data: {
                        xLabels: data.xlabels,
                        datasets: [{
                            label: data.labels.map(label => label.label)[0],
                            data: data.points[0] as unknown as number[],
                            borderWidth: 2,
                            backgroundColor: data.labels.map(label => label.color)[0],
                            borderColor: data.labels.map(label => label.color)[0],
                        }],
                    },
                    options: {
                        plugins: {
                            legend: {
                                display: elementData.ShowLegend,
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                }
                return result as GadsChart<T>;
            }
        case 'pie':
            {
                const result: PieChartConfig = {
                    type: 'pie',
                    data: {
                        labels: data.points[0].map(point => {
                            return getPointLabel(point)
                        }),
                        datasets: [{
                            label: data.labels.map(label => label.label)[0],
                            data: data.points[0].map(point => getPointValue(point)),
                        }]
                    }
                }
                return result as GadsChart<T>;
            }
        case 'doughnut':
        case 'donut':
            {
                const result: DoughnutChartConfig = {
                    type: 'doughnut',
                    data: {
                        labels: data.points[0].map(point => {
                            return getPointLabel(point)
                        }),
                        datasets: [{
                            label: data.labels.map(label => label.label)[0],
                            data: data.points[0].map(point => getPointValue(point)),
                        }],
                    },
                }
                return result as GadsChart<T>;
            }
        default:
            {
                throw new Error('Invalid GraphType');
            }
    }
}
