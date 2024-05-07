"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[353],{75198:(t,e,n)=>{n.r(e),n.d(e,{default:()=>m});n(50886),n(34284),n(69373),n(59903),n(59749),n(86544),n(60228),n(79288),n(84254),n(752),n(21694),n(76265),n(47522);var r=function(t){var e=[],n=0;return t.records.forEach((function(t){t instanceof Object?e.push({name:t.label,id:t.id}):e.push({name:t,id:n++})})),e};function i(t){return i="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},i(t)}function o(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(o=r.key,a=void 0,a=function(t,e){if("object"!==i(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==i(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(o,"string"),"symbol"===i(a)?a:String(a)),r)}var o,a}function a(t,e,n){return e&&o(t.prototype,e),n&&o(t,n),Object.defineProperty(t,"prototype",{writable:!1}),t}var u=a((function t(e,n,r,i,o,a){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.name=e,this.ajaxSource=n,this.mapper=r,this.appendQuery=i,this.data=o,this.dataBuilder=a})),c=(n(64043),n(7409),n(53943),n(95469)),s=n.n(c);function l(t){return l="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},l(t)}function f(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(i=r.key,o=void 0,o=function(t,e){if("object"!==l(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==l(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(i,"string"),"symbol"===l(o)?o:String(o)),r)}var i,o}var p=function(){function t(e,n,r){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.$input=e,this.callback=n,this.sourceOptions=r,this.init()}var e,n,r;return e=t,(n=[{key:"init",value:function(){var t=this,e=this.sourceOptions,n=e.appendQuery,r=e.mapper,i=e.name,o=e.ajaxSource,a=new(s())({datumTokenizer:s().tokenizers.whitespace,queryTokenizer:s().tokenizers.whitespace,remote:{url:o+(n?"%QUERY":""),wildcard:"%QUERY",transform:function(t){return r(t)},rateLimitBy:"debounce",rateLimitWait:300,cache:!1}});this.$input.typeahead({hint:!1,highlight:!1,minLength:0},{name:i,source:a,display:"name",limit:20,templates:{suggestion:function(t){return"<div>".concat(t.name,"</div>")},pending:function(){return"<div>Loading...</div>"},notFound:function(){return"<div>No results found</div>"}}}),this.$input.on("typeahead:select",(function(e,n){t.callback(n)})),window.test&&(this.$input.on("typeahead:asyncrequest",(function(){console.log("Typeahead async request")})),this.$input.on("typeahead:asyncreceive",(function(){console.log("Typeahead async receive")})),this.$input.on("typeahead:asynccancel",(function(){console.log("Typeahead async cancel")})))}}])&&f(e.prototype,n),r&&f(e,r),Object.defineProperty(e,"prototype",{writable:!1}),t}();function h(t){return h="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},h(t)}function y(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(i=r.key,o=void 0,o=function(t,e){if("object"!==h(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==h(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(i,"string"),"symbol"===h(o)?o:String(o)),r)}var i,o}const m=function(){function t(){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.mapper=function(t){return t.map((function(t){return{name:t.name,id:t.id}}))},this.appendQuery=!1,this.data=void 0}var e,n,i;return e=t,n=[{key:"withInput",value:function(t){return this.$input=t,this}},{key:"withCallback",value:function(t){return this.callback=t,this}},{key:"withName",value:function(t){return this.name=t,this}},{key:"withAjaxSource",value:function(t){return this.ajaxSource=t,this}},{key:"withAppendQuery",value:function(){var t=!(arguments.length>0&&void 0!==arguments[0])||arguments[0];return this.appendQuery=t,this}},{key:"withData",value:function(t){return this.dataBuilder=void 0,this.data=t,this}},{key:"withMapper",value:function(t){return this.mapper=t,this}},{key:"withDefaultMapper",value:function(){return this.mapper=r,this}},{key:"withDataBuilder",value:function(t){return this.data=void 0,this.dataBuilder=t,this}},{key:"build",value:function(){if(!this.$input)throw new Error("Input not set");if(!this.callback)throw new Error("Callback not set");if(!this.name)throw new Error("Name not set");if(!this.ajaxSource)throw new Error("Ajax source not set");var t=new u(this.name,this.ajaxSource,this.mapper,this.appendQuery,this.data,this.dataBuilder);return new p(this.$input,this.callback,t)}}],n&&y(e.prototype,n),i&&y(e,i),Object.defineProperty(e,"prototype",{writable:!1}),t}()}}]);