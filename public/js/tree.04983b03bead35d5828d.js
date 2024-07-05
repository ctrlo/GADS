"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[623],{20298:(e,t,n)=>{n.r(t),n.d(t,{default:()=>h});n(52675),n(89463),n(2259),n(45700),n(28706),n(50113),n(23792),n(89572),n(2892),n(40875),n(26099),n(60825),n(47764),n(62953);var r=n(17527),i=(n(91460),n(56197)),o=n(74692);function a(e){return a="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},a(e)}function l(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,c(r.key),r)}}function c(e){var t=function(e,t){if("object"!=a(e)||!e)return e;var n=e[Symbol.toPrimitive];if(void 0!==n){var r=n.call(e,t||"default");if("object"!=a(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(e,"string");return"symbol"==a(t)?t:t+""}function s(e,t,n){return t=d(t),function(e,t){if(t&&("object"===a(t)||"function"==typeof t))return t;if(void 0!==t)throw new TypeError("Derived constructors may only return object or undefined");return function(e){if(void 0===e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return e}(e)}(e,u()?Reflect.construct(t,n||[],d(e).constructor):t.apply(e,n))}function u(){try{var e=!Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){})))}catch(e){}return(u=function(){return!!e})()}function d(e){return d=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(e){return e.__proto__||Object.getPrototypeOf(e)},d(e)}function f(e,t){return f=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(e,t){return e.__proto__=t,e},f(e,t)}const h=function(e){function t(e){var n;return function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,t),(n=s(this,t,[e])).el=o(n.element),n.isConfTree=n.el.hasClass("tree--config"),n.el.find(".tree-widget-container").length>0&&(n.multiValue=n.el.closest(".linkspace-field").data("is-multivalue"),n.noInitialData=n.el.data("no-initial-data"),n.$treeContainer=n.el.find(".tree-widget-container"),n.id=n.$treeContainer.data("column-id"),n.field=n.$treeContainer.data("field"),n.endNodeOnly=n.$treeContainer.data("end-node-only"),n.initialized=!1,n.initTree()),n}return function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function");e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,writable:!0,configurable:!0}}),Object.defineProperty(e,"prototype",{writable:!1}),t&&f(e,t)}(t,e),n=t,(r=[{key:"initTree",value:function(){var e,t=this,n=this.$treeContainer.data("ids-as-params"),r={core:{check_callback:!0,force_text:!0,themes:{stripes:!1},worker:!1,data:this.noInitialData?null:this.getData(this.id,n)},plugins:[]};this.multiValue?r.plugins.push("checkbox"):r.core.multiple=!1,this.isConfTree||this.$treeContainer.on("changed.jstree",(function(e,n){return t.handleChange(e,n)})),this.$treeContainer.on("click",".jstree-clicked",(function(){if(!e)throw"Not a node!";t.$treeContainer.jstree(!0).deselect_node(e)})),this.$treeContainer.on("select_node.jstree",(function(n,r){e&&r.node.id==e.id?(t.$treeContainer.jstree(!0).deselect_node(r.node),e=null):(e=r.node,t.handleSelect(n,r))})),this.$treeContainer.on("ready.jstree",(function(){(0,i.pT)(t.el),t.initialized=!0})),this.$treeContainer.on("changed.jstree",(function(){return(0,i.Pc)(t.el)})),this.$treeContainer.jstree(r),this.setupJStreeButtons(this.$treeContainer),this.$treeContainer.jstree(!0).settings.checkbox.cascade="undetermined"}},{key:"getData",value:function(e,t){var n=window.siteConfig&&window.siteConfig.urls.treeApi,r=o("body").data("layout-identifier");return{url:function(){return n||"/".concat(r,"/tree").concat((new Date).getTime(),"/").concat(e,"?").concat(t)},data:function(e){return{id:e.id}},dataType:"json"}}},{key:"handleSelect",value:function(e,t){0!=t.node.children.length&&(this.endNodeOnly?(this.$treeContainer.jstree(!0).deselect_node(t.node),this.$treeContainer.jstree(!0).toggle_node(t.node)):this.multiValue&&this.$treeContainer.jstree(!0).open_node(t.node))}},{key:"handleChange",value:function(e,t){var n=this;this.$treeContainer.nextAll(".selected-tree-value").remove();var r=this.$treeContainer.jstree("get_selected",!0);o.each(r,(function(e,r){var i=o('<input type="hidden" class="selected-tree-value" name="'.concat(n.field,'" value="').concat(r.id,'" />')).appendTo(n.$treeContainer.closest(".tree")),a=t.instance.get_path(r,"#");i.data("text-value",a)})),0==r.length&&this.$treeContainer.after('<input type="hidden" class="selected-tree-value" name="'.concat(this.field,'" value="" />')),this.initialized&&this.$treeContainer.trigger("change")}},{key:"setupJStreeButtons",value:function(e){var t=this,n=this.el.find(".btn-js-tree-expand"),r=this.el.find(".btn-js-tree-collapse"),i=this.el.find(".btn-js-tree-reload"),o=this.el.find(".btn-js-tree-add"),a=this.el.find(".btn-js-tree-rename"),l=this.el.find(".btn-js-tree-delete");n.on("click",(function(){e.jstree("open_all")})),r.on("click",(function(){e.jstree("close_all")})),i.on("click",(function(){e.jstree("refresh")})),o.on("click",(function(){t.handleAdd()})),a.on("click",(function(){t.handleRename()})),l.on("click",(function(){t.handleDelete()}))}},{key:"handleAdd",value:function(){var e=this.$treeContainer.jstree(!0),t=e.get_selected();t=t.length?t[0]:"#",(t=e.create_node(t,{type:"file"}))&&e.edit(t)}},{key:"handleDelete",value:function(){var e=this.$treeContainer.jstree(!0),t=e.get_selected();if(!t.length)return!1;e.delete_node(t)}},{key:"handleRename",value:function(){var e=this.$treeContainer.jstree(!0),t=e.get_selected();if(!t.length)return!1;t=t[0],e.edit(t)}}])&&l(n.prototype,r),a&&l(n,a),Object.defineProperty(n,"prototype",{writable:!1}),n;var n,r,a}(r.uA)}}]);