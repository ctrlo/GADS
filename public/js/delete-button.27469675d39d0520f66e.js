"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[976],{39265:(t,o,e)=>{e.r(o),e.d(o,{default:()=>r});e(25728),e(60228);var n=e(60387),i=e(19755);function r(t){var o=this;t.on("click",(function(t){var e=i(t.target).closest("button"),r=e.attr("data-title"),a=e.attr("data-id"),l=e.attr("data-target"),c=e.attr("data-toggle"),u=r?"Delete - ".concat(r):"Delete",s=i(document).find(".modal--delete".concat(l));try{if(!(a&&l&&c))throw"Delete button should have data attributes id, toggle and target!";if(0===s.length)throw"There is no modal with id: ".concat(l)}catch(t){n.P.error(t),o.el.on("click",(function(t){t.stopPropagation()}))}s.find(".modal-title").text(u),s.find("button[type=submit]").val(a)}))}},60387:(t,o,e)=>{e.d(o,{P:()=>r});e(2918),e(69373),e(59903),e(59749),e(86544),e(60228),e(79288),e(84254),e(752),e(21694),e(76265);function n(t){return n="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},n(t)}function i(t,o){for(var e=0;e<o.length;e++){var i=o[e];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(t,(r=i.key,a=void 0,a=function(t,o){if("object"!==n(t)||null===t)return t;var e=t[Symbol.toPrimitive];if(void 0!==e){var i=e.call(t,o||"default");if("object"!==n(i))return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===o?String:Number)(t)}(r,"string"),"symbol"===n(a)?a:String(a)),i)}var r,a}var r=new(function(){function t(){!function(t,o){if(!(t instanceof o))throw new TypeError("Cannot call a class as a function")}(this,t),this.allowLogging="localhost"===location.hostname||"127.0.0.1"===location.hostname||location.hostname.endsWith(".peek.digitpaint.nl")}var o,e,n;return o=t,(e=[{key:"log",value:function(t){this.allowLogging&&console.log(t)}},{key:"info",value:function(t){this.allowLogging&&console.info(t)}},{key:"warn",value:function(t){this.allowLogging&&console.warn(t)}},{key:"error",value:function(t){this.allowLogging&&console.error(t)}}])&&i(o.prototype,e),n&&i(o,n),Object.defineProperty(o,"prototype",{writable:!1}),t}())},2918:(t,o,e)=>{var n,i=e(79989),r=e(46576),a=e(82474).f,l=e(43126),c=e(34327),u=e(42124),s=e(74684),f=e(27413),g=e(53931),d=r("".endsWith),h=r("".slice),p=Math.min,y=f("endsWith");i({target:"String",proto:!0,forced:!!(g||y||(n=a(String.prototype,"endsWith"),!n||n.writable))&&!y},{endsWith:function(t){var o=c(s(this));u(t);var e=arguments.length>1?arguments[1]:void 0,n=o.length,i=void 0===e?n:p(l(e),n),r=c(t);return d?d(o,r,i):h(o,i-r.length,i)===r}})}}]);