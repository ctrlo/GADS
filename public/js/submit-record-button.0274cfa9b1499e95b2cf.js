"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[956],{35871:(e,r,t)=>{t.r(r),t.d(r,{default:()=>u});t(52675),t(89463),t(2259),t(45700),t(28706),t(50113),t(23792),t(89572),t(2892),t(26099),t(47764),t(62953);var n=t(56197),o=t(74692);function i(e){return i="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},i(e)}function a(e,r){for(var t=0;t<r.length;t++){var n=r[t];n.enumerable=n.enumerable||!1,n.configurable=!0,"value"in n&&(n.writable=!0),Object.defineProperty(e,l(n.key),n)}}function d(e,r,t){return r&&a(e.prototype,r),t&&a(e,t),Object.defineProperty(e,"prototype",{writable:!1}),e}function l(e){var r=function(e,r){if("object"!=i(e)||!e)return e;var t=e[Symbol.toPrimitive];if(void 0!==t){var n=t.call(e,r||"default");if("object"!=i(n))return n;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===r?String:Number)(e)}(e,"string");return"symbol"==i(r)?r:r+""}var u=d((function e(r){var t=this;!function(e,r){if(!(e instanceof r))throw new TypeError("Cannot call a class as a function")}(this,e),this.el=r,this.requiredHiddenRecordDependentFieldsCleared=!1,this.canSubmitRecordForm=!1,this.disableButton=!1,this.el.on("click",(function(e){var r=o(e.target).closest("button"),i=r.closest("form"),a=i.find(".form-group[data-has-dependency='1'][style*='display: none'] *[aria-required]"),d=r.closest(".modal-body");(t.requiredHiddenRecordDependentFieldsCleared||(e.preventDefault(),a.removeAttr("required"),t.requiredHiddenRecordDependentFieldsCleared=!0),t.canSubmitRecordForm)||(e.preventDefault(),(0,n.Rv)(i)?(t.canSubmitRecordForm=!0,t.disableButton=!1,d.hasClass("modal-body")?i.trigger("submit"):r.trigger("click"),t.disableButton=!0,r.prop("disabled",!0),r.prop("name")&&r.after('<input type="hidden" name="'.concat(r.prop("name"),'" value="').concat(r.val(),'" />'))):(a.attr("required",""),t.requiredHiddenRecordDependentFieldsCleared=!1));t.disableButton&&r.prop("disabled",t.requiredHiddenRecordDependentFieldsCleared)}))}))}}]);