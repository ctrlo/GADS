"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[384],{66223:(a,e,t)=>{t.r(e),t.d(e,{addRow:()=>o,clearTable:()=>i,getRowOrder:()=>c,transferRowToTable:()=>l,updateRow:()=>n});t(25728),t(60228),t(32320);var r=t(19755),o=function(a,e){arguments.length>2&&void 0!==arguments[2]&&arguments[2]?d(a,e):e.DataTable().row.add(a).draw()},n=function(a,e,t){e.find("tbody > tr").each((function(o,n){r(n).has("button[data-tempid=".concat(t,"]")).length&&e.DataTable().row(o).data(a).draw()}))},i=function(a){a.DataTable().clear().draw()},d=function(a,e){var t=e.DataTable();t.row.add(a).draw("page");for(var r=t.data().length-1,o=t.row(r),n=c(o),i=r;i>0;i--){var d=(o=t.row(i)).data(),l=t.row(i-1);if(c(l)<n)break;t.row(i).data(l.data()),t.row(i-1).data(d)}t.page(t.page()).draw(!1)},c=function(a){try{var e=r(a.node()).find("input").first().data("order");return void 0===e?-1:parseInt(e)}catch(a){return-1}},l=function(a,e,t){if(void 0!==e){var n=r(e),i=a.find("input").first();if(0===i.length&&console.error("Failed to move row from table '".concat(e,"'; missing checkbox input element")),i.attr("checked",!i.prop("checked")),void 0!==t){var d=r(t),l=n.DataTable().row(a),s=c(l)>-1;s||console.warn("Failed to move row to correct position in '".concat(t,"'; missing data-order attribute in checkbox input element")),l.invalidate(),o(l.data(),d,s),l.remove().draw("page")}else console.error("Failed to move row; missing 'transfer-destination' data attribute for table '".concat(e,"'"))}else console.error("Failed to move row; missing sourceTableID")}}}]);