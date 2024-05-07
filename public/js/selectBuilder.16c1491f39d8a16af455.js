"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[845],{86367:(e,t,n)=>{n.r(t),n.d(t,{default:()=>g});n(88052),n(76034),n(30050),n(84254),n(752),n(21694),n(76265),n(25728),n(60228),n(32320),n(12826),n(34338),n(69373),n(59903),n(59749),n(86544),n(79288);var i=n(53865),o=n(22092),r=n(19755);function a(e){return a="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},a(e)}function s(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,d(i.key),i)}}function l(e,t){return l=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(e,t){return e.__proto__=t,e},l(e,t)}function u(e){var t=function(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(e){return!1}}();return function(){var n,i=c(e);if(t){var o=c(this).constructor;n=Reflect.construct(i,arguments,o)}else n=i.apply(this,arguments);return function(e,t){if(t&&("object"===a(t)||"function"==typeof t))return t;if(void 0!==t)throw new TypeError("Derived constructors may only return object or undefined");return function(e){if(void 0===e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return e}(e)}(this,n)}}function c(e){return c=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(e){return e.__proto__||Object.getPrototypeOf(e)},c(e)}function d(e){var t=function(e,t){if("object"!==a(e)||null===e)return e;var n=e[Symbol.toPrimitive];if(void 0!==n){var i=n.call(e,t||"default");if("object"!==a(i))return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(e,"string");return"symbol"===a(t)?t:String(t)}var p,f,h,v="select__placeholder",y="select__menu-item--active",b="select__menu-item--hover",m=function(e){!function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function");e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,writable:!0,configurable:!0}}),Object.defineProperty(e,"prototype",{writable:!1}),t&&l(e,t)}(c,e);var t,n,i,a=u(c);function c(e){var t;return function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,c),(t=a.call(this,e)).el=r(t.element),t.toggleButton=t.el.find(".select__toggle"),t.input=t.el.find("input"),t.menu=t.el.find(".select__menu"),t.options=t.el.find(".select__menu-item"),t.optionChecked="",t.optionHoveredIndex=-1,t.optionsCount=t.options.length,t.isSelectReveal=t.el.hasClass("select--reveal"),t.initSelect(t.el),t.el.hasClass("select--required")&&(0,o.Kg)(t.el),t}return t=c,(n=[{key:"initSelect",value:function(){var e=this;this.options&&(this.options.on("click",(function(t){e.handleClick(t)})),this.input.on("change",(function(t){e.handleChange(t)})),this.el.on("show.bs.dropdown",(function(){e.handleOpen()})),this.input.val()&&this.input.trigger("change"))}},{key:"addOption",value:function(e,t){var n=document.createElement("li");n.classList.add("select__menu-item"),n.setAttribute("role","option"),n.setAttribute("aria-selected","false"),n.setAttribute("data-id",e),n.setAttribute("data-value",t),n.innerHTML=e,this.menu.append(n),this.bindOptionHandler(n),this.options=this.el.find(".select__menu-item")}},{key:"removeOption",value:function(e){this.options.each((function(t,n){parseInt(n.dataset.value)===e&&n.remove()}))}},{key:"updateOption",value:function(e,t){this.options.each((function(n,i){parseInt(i.dataset.value)===t&&(i.setAttribute("data-id",e),i.innerHTML=e)}))}},{key:"bindOptionHandler",value:function(e){var t=this;r(e).on("click",(function(e){t.handleClick(e)}))}},{key:"handleOpen",value:function(){var e=this;this.el.on("keydown",(function(t){e.supportKeyboardNavigation(t)}))}},{key:"handleClose",value:function(e){this.el.dropdown("hide"),e.stopPropagation(),this.el.off("keydown")}},{key:"handleChange",value:function(e){var t=this,n=r(e.target).val();""===n?this.resetSelect():this.options.each((function(e,i){r(i).data("value").toString()===n&&(t.updateChecked(r(i)),t.isSelectReveal&&t.revealInstance(r(i)))}))}},{key:"handleClick",value:function(e){var t=r(e.target),n=t.data("value"),i=t.data("reveal_id");this.input.val(n).trigger("change"),void 0!==i&&this.input.attr("data-reveal_id",i),this.updateChecked(r(t)),this.isSelectReveal&&this.revealInstance(r(t)),this.toggleButton.trigger("focus")}},{key:"revealInstance",value:function(e){var t=this,n=r(".select-reveal--".concat(this.input.attr("id")," > .select-reveal__instance")),i="";i=void 0!==e.data("reveal_id")?"#".concat(this.input.attr("id"),"_").concat(e.data("reveal_id")):"#".concat(this.input.attr("id"),"_").concat(e.data("value")),n.each((function(e,n){r(n).hide(),t.disableFields(n,!0)})),r(i).show(),this.disableFields(r(i),!1)}},{key:"disableFields",value:function(e,t){var n=r(e).find("input, textarea");t?n.prop("disabled",!0):n.removeAttr("disabled")}},{key:"updateHovered",value:function(e){var t=this.options[this.optionHoveredIndex],n=this.options[e];t&&t.classList.remove(b),n&&n.classList.add(b),this.optionHoveredIndex=e}},{key:"updateChecked",value:function(e){var t=r(e).data("value"),n=r(e).html();this.toggleButton.find("span").html(n),this.toggleButton.find("span").removeClass(v),this.options.removeClass(y),this.options.attr("aria-selected",!1),r(e).addClass(y),r(e).attr("aria-selected",!0),this.optionChecked=t}},{key:"supportKeyboardNavigation",value:function(e){if(40===e.keyCode&&this.optionHoveredIndex<this.optionsCount-1&&(e.preventDefault(),this.updateHovered(this.optionHoveredIndex+1)),38===e.keyCode&&this.optionHoveredIndex>0&&(e.preventDefault(),this.updateHovered(this.optionHoveredIndex-1)),13===e.keyCode||32===e.keyCode){e.preventDefault();var t=this.options[this.optionHoveredIndex],n=t&&r(t).data("value");n&&this.input.val(n).trigger("change"),this.handleClose(e)}27===e.keyCode&&this.handleClose(e)}},{key:"resetSelect",value:function(){var e=this.input[0].placeholder;this.toggleButton.find("span").html(e),this.toggleButton.find("span").addClass(v),this.options.removeClass(y),this.options.attr("aria-selected",!1),this.input.removeAttr("value"),this.input.removeAttr("data-restore-value")}}])&&s(t.prototype,n),i&&s(t,i),Object.defineProperty(t,"prototype",{writable:!1}),c}(i.wA);p=m,h=m,(f=d(f="self"))in p?Object.defineProperty(p,f,{value:h,enumerable:!0,configurable:!0,writable:!0}):p[f]=h;const g=m}}]);