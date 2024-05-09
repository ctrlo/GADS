"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[714],{67714:(t,e,n)=>{n.r(e),n.d(e,{default:()=>s});n(76801),n(43843),n(88052),n(60228),n(76034),n(30050),n(69373),n(59903),n(59749),n(86544),n(79288),n(84254),n(752),n(21694),n(76265);var o=n(53865),r=(n(11055),n(60387)),i=n(19755);function a(t){return a="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},a(t)}function l(t,e){for(var n=0;n<e.length;n++){var o=e[n];o.enumerable=o.enumerable||!1,o.configurable=!0,"value"in o&&(o.writable=!0),Object.defineProperty(t,(r=o.key,i=void 0,i=function(t,e){if("object"!==a(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var o=n.call(t,e||"default");if("object"!==a(o))return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(r,"string"),"symbol"===a(i)?i:String(i)),o)}var r,i}function u(t,e){return u=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(t,e){return t.__proto__=e,t},u(t,e)}function c(t){var e=function(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(t){return!1}}();return function(){var n,o=f(t);if(e){var r=f(this).constructor;n=Reflect.construct(o,arguments,r)}else n=o.apply(this,arguments);return function(t,e){if(e&&("object"===a(e)||"function"==typeof e))return e;if(void 0!==e)throw new TypeError("Derived constructors may only return object or undefined");return function(t){if(void 0===t)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return t}(t)}(this,n)}}function f(t){return f=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(t){return t.__proto__||Object.getPrototypeOf(t)},f(t)}const s=function(t){!function(t,e){if("function"!=typeof e&&null!==e)throw new TypeError("Super expression must either be null or a function");t.prototype=Object.create(e&&e.prototype,{constructor:{value:t,writable:!0,configurable:!0}}),Object.defineProperty(t,"prototype",{writable:!1}),e&&u(t,e)}(f,t);var e,n,o,a=c(f);function f(t){var e;return function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,f),(e=a.call(this,t)).initSummerNote(),e}return e=f,(n=[{key:"initSummerNote",value:function(){var t=this;i(this.element).summernote({toolbar:[["style",["style"]],["font",["bold","underline","clear"]],["fontname",["fontname"]],["color",["color"]],["para",["ul","ol","paragraph"]],["table",["table"]],["insert",["link","picture","video"]],["view",["codeview","help"]]],dialogsInBody:!0,height:400,callbacks:{onInit:function(){var t=i(this).siblings("input[type=hidden].summernote_content");i(this).summernote("code",t.val())},onImageUpload:function(e){for(var n=0;n<e.length;n++)t.handleHtmlEditorFileUpload(e[n],this)},onChange:function(t){var e=i(this).closest(".summernote");e.summernote("isEmpty")&&(t=""),e.siblings("input[type=hidden].summernote_content").val(t)}}})}},{key:"handleHtmlEditorFileUpload",value:function(t,e){if(t.type.includes("image")){var n=new FormData;n.append("file",t),n.append("csrf_token",i("body").data("csrf")),i.ajax({url:"/file?ajax&is_independent",type:"POST",contentType:!1,cache:!1,processData:!1,dataType:"JSON",data:n,success:function(t){t.is_ok?i(e).summernote("editor.insertImage",t.url):r.P.error(t.error)}}).fail((function(t){r.P.error(t)}))}else r.P.error("The type of file uploaded was not an image")}}])&&l(e.prototype,n),o&&l(e,o),Object.defineProperty(e,"prototype",{writable:!1}),f}(o.wA)},60387:(t,e,n)=>{n.d(e,{P:()=>i});n(2918),n(69373),n(59903),n(59749),n(86544),n(60228),n(79288),n(84254),n(752),n(21694),n(76265);function o(t){return o="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},o(t)}function r(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(i=r.key,a=void 0,a=function(t,e){if("object"!==o(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==o(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(i,"string"),"symbol"===o(a)?a:String(a)),r)}var i,a}var i=new(function(){function t(){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.allowLogging="localhost"===location.hostname||"127.0.0.1"===location.hostname||location.hostname.endsWith(".peek.digitpaint.nl")}var e,n,o;return e=t,(n=[{key:"log",value:function(t){this.allowLogging&&console.log(t)}},{key:"info",value:function(t){this.allowLogging&&console.info(t)}},{key:"warn",value:function(t){this.allowLogging&&console.warn(t)}},{key:"error",value:function(t){this.allowLogging&&console.error(t)}}])&&r(e.prototype,n),o&&r(e,o),Object.defineProperty(e,"prototype",{writable:!1}),t}())}}]);