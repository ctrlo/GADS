"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([["tree"],{"./src/frontend/components/form-group/tree/lib/component.js":(e,t,n)=>{n.r(t),n.d(t,{default:()=>d});n("./node_modules/core-js/modules/es.array.find.js"),n("./node_modules/core-js/modules/es.object.to-string.js"),n("./node_modules/core-js/modules/es.array.concat.js"),n("./node_modules/core-js/modules/es.object.get-prototype-of.js"),n("./node_modules/core-js/modules/es.reflect.to-string-tag.js"),n("./node_modules/core-js/modules/es.reflect.construct.js"),n("./node_modules/core-js/modules/es.symbol.to-primitive.js"),n("./node_modules/core-js/modules/es.date.to-primitive.js"),n("./node_modules/core-js/modules/es.symbol.js"),n("./node_modules/core-js/modules/es.symbol.description.js"),n("./node_modules/core-js/modules/es.number.constructor.js"),n("./node_modules/core-js/modules/es.symbol.iterator.js"),n("./node_modules/core-js/modules/es.array.iterator.js"),n("./node_modules/core-js/modules/es.string.iterator.js"),n("./node_modules/core-js/modules/web.dom-collections.iterator.js");var o=n("./src/frontend/js/lib/component.js"),r=(n("./node_modules/jstree/dist/jstree.js"),n("./src/frontend/js/lib/validation.js")),i=n("./node_modules/jquery/dist/jquery.js");function s(e){return s="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},s(e)}function l(e,t){for(var n=0;n<t.length;n++){var o=t[n];o.enumerable=o.enumerable||!1,o.configurable=!0,"value"in o&&(o.writable=!0),Object.defineProperty(e,(r=o.key,i=void 0,i=function(e,t){if("object"!==s(e)||null===e)return e;var n=e[Symbol.toPrimitive];if(void 0!==n){var o=n.call(e,t||"default");if("object"!==s(o))return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(r,"string"),"symbol"===s(i)?i:String(i)),o)}var r,i}function a(e,t){return a=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(e,t){return e.__proto__=t,e},a(e,t)}function c(e){var t=function(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(e){return!1}}();return function(){var n,o=u(e);if(t){var r=u(this).constructor;n=Reflect.construct(o,arguments,r)}else n=o.apply(this,arguments);return function(e,t){if(t&&("object"===s(t)||"function"==typeof t))return t;if(void 0!==t)throw new TypeError("Derived constructors may only return object or undefined");return function(e){if(void 0===e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return e}(e)}(this,n)}}function u(e){return u=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(e){return e.__proto__||Object.getPrototypeOf(e)},u(e)}const d=function(e){!function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function");e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,writable:!0,configurable:!0}}),Object.defineProperty(e,"prototype",{writable:!1}),t&&a(e,t)}(u,e);var t,n,o,s=c(u);function u(e){var t;return function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,u),(t=s.call(this,e)).el=i(t.element),t.isConfTree=t.el.hasClass("tree--config"),t.el.find(".tree-widget-container").length>0&&(t.multiValue=t.el.closest(".linkspace-field").data("is-multivalue"),t.noInitialData=t.el.data("no-initial-data"),t.$treeContainer=t.el.find(".tree-widget-container"),t.id=t.$treeContainer.data("column-id"),t.field=t.$treeContainer.data("field"),t.endNodeOnly=t.$treeContainer.data("end-node-only"),t.initTree()),t}return t=u,(n=[{key:"initTree",value:function(){var e=this,t=this.$treeContainer.data("ids-as-params"),n={core:{check_callback:!0,force_text:!0,themes:{stripes:!1},worker:!1,data:this.noInitialData?null:this.getData(this.id,t)},plugins:[]};this.multiValue?n.plugins.push("checkbox"):n.core.multiple=!1,this.isConfTree||this.$treeContainer.on("changed.jstree",(function(t,n){return e.handleChange(t,n)})),this.$treeContainer.on("select_node.jstree",(function(t,n){return e.handleSelect(t,n)})),this.$treeContainer.on("ready.jstree",(function(){return(0,r.initValidationOnField)(e.el)})),this.$treeContainer.on("changed.jstree",(function(){return(0,r.validateTree)(e.el)})),this.$treeContainer.jstree(n),this.setupJStreeButtons(this.$treeContainer),this.$treeContainer.jstree(!0).settings.checkbox.cascade="undetermined"}},{key:"getData",value:function(e,t){var n=window.siteConfig&&window.siteConfig.urls.treeApi,o=i("body").data("layout-identifier");return{url:function(){return n||"/".concat(o,"/tree").concat((new Date).getTime(),"/").concat(e,"?").concat(t)},data:function(e){return{id:e.id}},dataType:"json"}}},{key:"handleSelect",value:function(e,t){0!=t.node.children.length&&(this.endNodeOnly?(this.$treeContainer.jstree(!0).deselect_node(t.node),this.$treeContainer.jstree(!0).toggle_node(t.node)):this.multiValue&&this.$treeContainer.jstree(!0).open_node(t.node))}},{key:"handleChange",value:function(e,t){this.$treeContainer.nextAll(".selected-tree-value").remove();var n=this.$treeContainer.jstree("get_selected",!0),o=this;i.each(n,(function(e,n){var r=i('<input type="hidden" class="selected-tree-value" name="'.concat(o.field,'" value="').concat(n.id,'" />')).insertAfter(o.$treeContainer),s=t.instance.get_path(n,"#");r.data("text-value",s)})),0==n.length&&o.$treeContainer.after('<input type="hidden" class="selected-tree-value" name="'.concat(o.field,'" value="" />')),o.$treeContainer.trigger("change")}},{key:"setupJStreeButtons",value:function(e){var t=this,n=this.el.find(".btn-js-tree-expand"),o=this.el.find(".btn-js-tree-collapse"),r=this.el.find(".btn-js-tree-reload"),i=this.el.find(".btn-js-tree-add"),s=this.el.find(".btn-js-tree-rename"),l=this.el.find(".btn-js-tree-delete");n.on("click",(function(t){e.jstree("open_all")})),o.on("click",(function(t){e.jstree("close_all")})),r.on("click",(function(t){e.jstree("refresh")})),i.on("click",(function(e){t.handleAdd()})),s.on("click",(function(e){t.handleRename()})),l.on("click",(function(e){t.handleDelete()}))}},{key:"handleAdd",value:function(){var e=this.$treeContainer.jstree(!0),t=e.get_selected();t=t.length?t[0]:"#",(t=e.create_node(t,{type:"file"}))&&e.edit(t)}},{key:"handleDelete",value:function(){var e=this.$treeContainer.jstree(!0),t=e.get_selected();if(!t.length)return!1;e.delete_node(t)}},{key:"handleRename",value:function(){var e=this.$treeContainer.jstree(!0),t=e.get_selected();if(!t.length)return!1;t=t[0],e.edit(t)}}])&&l(t.prototype,n),o&&l(t,o),Object.defineProperty(t,"prototype",{writable:!1}),u}(o.Component)}}]);
//# sourceMappingURL=tree.923f1768367ece5c8236.js.map