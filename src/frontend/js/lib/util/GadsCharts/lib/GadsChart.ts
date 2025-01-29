import { BasicData, ChartMap, ElementData, InputData } from "../types";
import { mapData } from "./mappers";
import Chart from "chart.js/auto";

export default function createChart(element: HTMLCanvasElement, data: BasicData, elementData?: InputData) {
  const ctx = $<HTMLCanvasElement>(element);
  let ed: ElementData;

  if (!elementData) {
    ed = {
      ChartId: $(ctx).data('chart-id'),
      GraphId: $(ctx).data('graph-id'),
      GraphType: $(ctx).data('graph-type') as keyof ChartMap,
      LayoutId: $(ctx).data('layout-id'),
      ShowLegend: $(ctx).data('showlegend'),
      StackSeries: $(ctx).data('stack-series'),
      XAxisName: $(ctx).data('x-axis-name'),
      YAxisLabel: $(ctx).data('y-axis-label'),
    }
  } else {
    ed = {
      ChartId: elementData.id,
      GraphType: elementData.type as keyof ChartMap,
      StackSeries: elementData.stackseries,
      ShowLegend: elementData.showlegend,
    }
  }

  const dataResult = mapData(ed, data);

  new Chart(ctx.get(0), dataResult);
}
