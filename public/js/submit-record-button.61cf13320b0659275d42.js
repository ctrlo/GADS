"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[754],{12511:(e,r,t)=>{t.r(r),t.d(r,{default:()=>l});t(25728),t(60228),t(34338),t(69373),t(59903),t(59749),t(86544),t(79288),t(84254),t(752),t(21694),t(76265);var n=t(22092),i=t(19755);function o(e){return o="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},o(e)}function a(e,r){for(var t=0;t<r.length;t++){var n=r[t];n.enumerable=n.enumerable||!1,n.configurable=!0,"value"in n&&(n.writable=!0),Object.defineProperty(e,(i=n.key,a=void 0,a=function(e,r){if("object"!==o(e)||null===e)return e;var t=e[Symbol.toPrimitive];if(void 0!==t){var n=t.call(e,r||"default");if("object"!==o(n))return n;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===r?String:Number)(e)}(i,"string"),"symbol"===o(a)?a:String(a)),n)}var i,a}function d(e,r,t){return r&&a(e.prototype,r),t&&a(e,t),Object.defineProperty(e,"prototype",{writable:!1}),e}var l=d((function e(r){var t=this;!function(e,r){if(!(e instanceof r))throw new TypeError("Cannot call a class as a function")}(this,e),this.el=r,this.requiredHiddenRecordDependentFieldsCleared=!1,this.canSubmitRecordForm=!1,this.disableButton=!1,this.el.on("click",(function(e){var r=i(e.target).closest("button"),o=r.closest("form"),a=o.find(".form-group[data-has-dependency='1'][style*='display: none'] *[aria-required]"),d=r.closest(".modal-body");(t.requiredHiddenRecordDependentFieldsCleared||(e.preventDefault(),a.removeAttr("required"),t.requiredHiddenRecordDependentFieldsCleared=!0),t.canSubmitRecordForm)||(e.preventDefault(),(0,n.MN)(o)?(t.canSubmitRecordForm=!0,t.disableButton=!1,d.hasClass("modal-body")?o.trigger("submit"):r.trigger("click"),t.disableButton=!0,r.prop("disabled",!0),r.prop("name")&&r.after('<input type="hidden" name="'.concat(r.prop("name"),'" value="').concat(r.val(),'" />'))):(a.attr("required",""),t.requiredHiddenRecordDependentFieldsCleared=!1));t.disableButton&&r.prop("disabled",t.requiredHiddenRecordDependentFieldsCleared)}))}))}}]);