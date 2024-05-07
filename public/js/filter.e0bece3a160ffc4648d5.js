"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[165],{25777:(e,t,r)=>{r.d(t,{o:()=>o});r(25728),r(60228),r(76801);var n=r(19755),o=function(e){var t=[],r=[];e.on("afterCreateRuleFilters.queryBuilder",(function(e,r){var o=n(r.$el.find("select[name=".concat(r.id,"_filter]")));t.includes(o[0])||t.push(o[0]),o&&o[0]?(o.data("live-search","true"),o.selectpicker()):console.error("No select found")})),e.on("afterCreateRuleOperators.queryBuilder",(function(e,t,o){var i=n(t.$el.find("select[name=".concat(t.id,"_operator]")));i&&i[0]?(r.includes(i[0])||r.push(i[0]),i.data("live-search")||(i.data("live-search","true"),i.selectpicker())):console.error("No operator select found")})),e.on("afterSetRules.queryBuilder",(function(){for(var e=0,o=t;e<o.length;e++){var i=o[e];i&&n(i).selectpicker("refresh")}for(var a=0,l=r;a<l.length;a++){var u=l[a];u&&n(u).selectpicker("refresh")}})),e.on("afterSetRuleOperator.queryBuilder",(function(){for(var e=0,t=r;e<t.length;e++){var o=t[e];o&&n(o).selectpicker("refresh")}}))}},50403:(e,t,r)=>{r.r(t),r.d(t,{default:()=>b});r(34338),r(25728),r(60228),r(69358),r(50886),r(47522),r(38077),r(34284),r(752),r(73964),r(21694),r(76265),r(48324),r(76801),r(69373),r(59903),r(59749),r(86544),r(79288),r(88052),r(76034),r(30050),r(81919),r(99474),r(84254);var n=r(53865),o=(r(96855),r(70300),r(60387)),i=r(25777),a=r(19755);function l(e){return l="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},l(e)}function u(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,n)}return r}function c(e,t){for(var r=0;r<t.length;r++){var n=t[r];n.enumerable=n.enumerable||!1,n.configurable=!0,"value"in n&&(n.writable=!0),Object.defineProperty(e,v(n.key),n)}}function s(e,t){return s=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(e,t){return e.__proto__=t,e},s(e,t)}function p(e){var t=function(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(e){return!1}}();return function(){var r,n=y(e);if(t){var o=y(this).constructor;r=Reflect.construct(n,arguments,o)}else r=n.apply(this,arguments);return function(e,t){if(t&&("object"===l(t)||"function"==typeof t))return t;if(void 0!==t)throw new TypeError("Derived constructors may only return object or undefined");return f(e)}(this,r)}}function f(e){if(void 0===e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return e}function y(e){return y=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(e){return e.__proto__||Object.getPrototypeOf(e)},y(e)}function d(e,t,r){return(t=v(t))in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function v(e){var t=function(e,t){if("object"!==l(e)||null===e)return e;var r=e[Symbol.toPrimitive];if(void 0!==r){var n=r.call(e,t||"default");if("object"!==l(n))return n;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(e,"string");return"symbol"===l(t)?t:String(t)}const b=function(e){!function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function");e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,writable:!0,configurable:!0}}),Object.defineProperty(e,"prototype",{writable:!1}),t&&s(e,t)}(v,e);var t,n,l,y=p(v);function v(e){var t;return function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,v),d(f(t=y.call(this,e)),"buildFilter",(function(e,r){return function(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?u(Object(r),!0).forEach((function(t){d(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):u(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}({id:r.filterId,label:r.label,type:"string",operators:t.buildFilterOperators(r.type)},"rag"===r.type?t.ragProperties:r.hasFilterTypeahead?t.typeaheadProperties(r.urlSuffix,e.layoutId,r.instanceId,r.useIdInFilter):{})})),d(f(t),"typeaheadProperties",(function(){return{input:function(e,t){return"<div class='tt__container'>\n          <input class='form-control typeahead_text' type='text' name='".concat(t,"_text'/>\n          <input class='form-control typeahead_hidden' type='hidden' name='").concat(t,"'/>\n        </div>")},valueSetter:function(e,t){e.$el.find(".typeahead_hidden").val(t);var r=e.$el.find(".typeahead_text");r.typeahead("val",e.data.text),r.val(e.data.text)},validation:{callback:function(){return!0}}}})),d(f(t),"getRecords",(function(e,r,n,o){return a.ajax({type:"GET",url:t.getURL(e,r),data:{q:o,oi:n},dataType:"json",path:"records"})})),t.el=a(t.element),t.operators=[{type:"equal",accept_values:!0,apply_to:["string","number","datetime"]},{type:"not_equal",accept_values:!0,apply_to:["string","number","datetime"]},{type:"less",accept_values:!0,apply_to:["string","number","datetime"]},{type:"less_or_equal",accept_values:!0,apply_to:["string","number","datetime"]},{type:"greater",accept_values:!0,apply_to:["string","number","datetime"]},{type:"greater_or_equal",accept_values:!0,apply_to:["string","number","datetime"]},{type:"contains",accept_values:!0,apply_to:["datetime","string"]},{type:"not_contains",accept_values:!0,apply_to:["datetime","string"]},{type:"begins_with",accept_values:!0,apply_to:["string"]},{type:"not_begins_with",accept_values:!0,apply_to:["string"]},{type:"is_empty",accept_values:!1,apply_to:["string","number","datetime"]},{type:"is_not_empty",accept_values:!1,apply_to:["string","number","datetime"]},{type:"changed_after",nb_inputs:1,accept_values:!0,multiple:!1,apply_to:["string","number","datetime"]}],t.ragProperties={input:"select",values:{b_red:"Red",c_amber:"Amber",c_yellow:"Yellow",d_green:"Green",a_grey:"Grey",e_purple:"Purple",d_blue:"Blue",b_attention:"Red (Attention)"}},t.initFilter(),t}return t=v,(n=[{key:"initFilter",value:function(){var e=this,t=this,n=this.el,l=a(this.el).data("builder-id"),u=a("#builder_json_".concat(l));if(u.length){var c=JSON.parse(u.html()),s=n.data("filter-base");if(c.filters.length&&(c.filterNotDone&&this.makeUpdateFilter(),(0,i.o)(this.el),n.queryBuilder({showPreviousValues:c.showPreviousValues,filters:c.filters.map((function(t){return e.buildFilter(c,t)})),allow_empty:!0,operators:this.operators,lang:{operators:{changed_after:"changed on or after"}}}),n.on("validationError.queryBuilder",(function(e,t,r,n){o.P.log(r),o.P.log(n),o.P.log(e),o.P.log(t)})),n.on("afterCreateRuleInput.queryBuilder",(function(e,n){var o;if(c.filters.forEach((function(e){if(e.filterId===n.filter.id)return o=e,!1})),o&&"rag"!==o.type&&o.hasFilterTypeahead){var i=a("#".concat(n.id," .rule-value-container input[type='text']")),l=a("#".concat(n.id," .rule-value-container input[type='hidden']"));i.attr("autocomplete","off"),i.on("keyup",(function(){l.val(i.val())}));var u=function(e){o.useIdInFilter?l.val(e.id):l.val(e.name)},s=function(){return{q:i.val(),oi:o.instanceId}};Promise.all([r.e(608),r.e(353)]).then(r.bind(r,75198)).then((function(e){(new(0,e.default)).withInput(i).withAjaxSource(t.getURL(c.layoutId,o.urlSuffix)).withDataBuilder(s).withDefaultMapper().withName("rule").withAppendQuery().withCallback(u).build()}))}})),s)){var p=atob(s);try{var f=JSON.parse(p);f.rules&&f.rules.length?n.queryBuilder("setRules",f):n.queryBuilder("setRules",{rules:[]})}catch(e){o.P.log("Incorrect data object passed to queryBuilder")}}}}},{key:"getURL",value:function(e,t){var r=window.siteConfig&&window.siteConfig.urls.filterApi;return r||"/".concat(e,"/match/layout/").concat(t,"?q=")}},{key:"makeUpdateFilter",value:function(){window.UpdateFilter=function(e,t){e.queryBuilder("validate")||t.preventDefault();var r=e.queryBuilder("getRules");a("#filter").val(JSON.stringify(r,null,2))}}},{key:"buildFilterOperators",value:function(e){if(["date","daterange"].includes(e)){var t=["equal","not_equal","less","less_or_equal","greater","greater_or_equal","is_empty","is_not_empty"];return"daterange"===e&&t.push("contain"),t}}}])&&c(t.prototype,n),l&&c(t,l),Object.defineProperty(t,"prototype",{writable:!1}),v}(n.wA)},60387:(e,t,r)=>{r.d(t,{P:()=>i});r(2918),r(69373),r(59903),r(59749),r(86544),r(60228),r(79288),r(84254),r(752),r(21694),r(76265);function n(e){return n="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},n(e)}function o(e,t){for(var r=0;r<t.length;r++){var o=t[r];o.enumerable=o.enumerable||!1,o.configurable=!0,"value"in o&&(o.writable=!0),Object.defineProperty(e,(i=o.key,a=void 0,a=function(e,t){if("object"!==n(e)||null===e)return e;var r=e[Symbol.toPrimitive];if(void 0!==r){var o=r.call(e,t||"default");if("object"!==n(o))return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(i,"string"),"symbol"===n(a)?a:String(a)),o)}var i,a}var i=new(function(){function e(){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this.allowLogging="localhost"===location.hostname||"127.0.0.1"===location.hostname||location.hostname.endsWith(".peek.digitpaint.nl")}var t,r,n;return t=e,(r=[{key:"log",value:function(e){this.allowLogging&&console.log(e)}},{key:"info",value:function(e){this.allowLogging&&console.info(e)}},{key:"warn",value:function(e){this.allowLogging&&console.warn(e)}},{key:"error",value:function(e){this.allowLogging&&console.error(e)}}])&&o(t.prototype,r),n&&o(t,n),Object.defineProperty(t,"prototype",{writable:!1}),e}())},81919:(e,t,r)=>{var n=r(79989),o=r(3689),i=r(65290),a=r(82474).f,l=r(67697);n({target:"Object",stat:!0,forced:!l||o((function(){a(1)})),sham:!l},{getOwnPropertyDescriptor:function(e,t){return a(i(e),t)}})},99474:(e,t,r)=>{var n=r(79989),o=r(67697),i=r(19152),a=r(65290),l=r(82474),u=r(76522);n({target:"Object",stat:!0,sham:!o},{getOwnPropertyDescriptors:function(e){for(var t,r,n=a(e),o=l.f,c=i(n),s={},p=0;c.length>p;)void 0!==(r=o(n,t=c[p++]))&&u(s,t,r);return s}})},2918:(e,t,r)=>{var n,o=r(79989),i=r(46576),a=r(82474).f,l=r(43126),u=r(34327),c=r(42124),s=r(74684),p=r(27413),f=r(53931),y=i("".endsWith),d=i("".slice),v=Math.min,b=p("endsWith");o({target:"String",proto:!0,forced:!!(f||b||(n=a(String.prototype,"endsWith"),!n||n.writable))&&!b},{endsWith:function(e){var t=u(s(this));c(e);var r=arguments.length>1?arguments[1]:void 0,n=t.length,o=void 0===r?n:v(l(r),n),i=u(e);return y?y(t,i,o):d(t,o-i.length,o)===i}})}}]);