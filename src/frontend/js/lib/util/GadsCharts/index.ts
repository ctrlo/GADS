import {BasicData} from "./types";
import createChart from "./lib/GadsChart";

declare global {
  interface JQuery<TElement extends HTMLElement = HTMLElement> {
    chart(options: any): JQuery<TElement>;
  }
}

(($) => {
  $.fn.chart = function(options: BasicData) {
    this.filter('canvas').each(function () {
      createChart(this, options);
    })
    return this;
  }
})(jQuery);
