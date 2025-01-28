import {BasicData, ChartMap, ElementData} from "../types";
import {mapData} from "./mappers";
import Chart from "chart.js/auto";

export default function createChart(element:HTMLCanvasElement, data: BasicData) {
  const ctx = $<HTMLCanvasElement>(element);

  const elementData: ElementData = {
    ChartId: $(ctx).data('chart-id'),
    GraphId: $(ctx).data('graph-id'),
    GraphType: $(ctx).data('graph-type') as keyof ChartMap,
    LayoutId: $(ctx).data('layout-id'),
    ShowLegend: $(ctx).data('showlegend'),
    StackSeries: $(ctx).data('stack-series'),
    XAxisName: $(ctx).data('x-axis-name'),
    YAxisLabel: $(ctx).data('y-axis-label'),
  }

  const dataResult = mapData(elementData, data);

  new Chart(ctx.get(0), dataResult);
}
