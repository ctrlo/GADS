"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([["dashboard"],{"./src/frontend/components/dashboard/lib/react/Footer.tsx":(e,t,n)=>{n.r(t),n.d(t,{default:()=>r});n("./node_modules/core-js/modules/es.array.map.js");var o=n("./node_modules/react/index.js");const r=function(e){var t=e.addWidget,n=e.widgetTypes,r=e.currentDashboard,s=e.readOnly,i=e.noDownload;return o.createElement("div",{className:"ld-footer-container"},i?null:o.createElement("div",{className:"btn-group mb-3 mb-md-0 mr-md-4"},o.createElement("button",{type:"button",className:"btn btn-default dropdown-toggle","data-toggle":"dropdown","aria-expanded":"false","aria-controls":"menu_view"},"Download ",o.createElement("span",{className:"caret"})),o.createElement("div",{className:"dropdown-menu dropdown__menu dropdown-menu-right scrollable-menu",role:"menu"},o.createElement("ul",{id:"menu_view",className:"dropdown__list"},o.createElement("li",{className:"dropdown__item"},o.createElement("a",{className:"link link--plain",href:r.download_url},"As PDF"))))),s?null:o.createElement("div",{className:"btn-group"},o.createElement("button",{type:"button",className:"btn btn-default dropdown-toggle","data-toggle":"dropdown","aria-expanded":"false","aria-controls":"menu_view"},"Add Widget"),o.createElement("div",{className:"dropdown-menu dropdown__menu dropdown-menu-right scrollable-menu",role:"menu"},o.createElement("ul",{id:"menu_view",className:"dropdown__list"},n.map((function(e){return o.createElement("li",{key:e,className:"dropdown__item"},o.createElement("a",{className:"link link--plain",href:"#",onClick:function(n){n.preventDefault(),t(e)}},e))}))))))}},"./src/frontend/components/dashboard/lib/react/Header.tsx":(e,t,n)=>{n.r(t),n.d(t,{default:()=>r});n("./node_modules/core-js/modules/es.function.name.js"),n("./node_modules/core-js/modules/es.array.map.js");var o=n("./node_modules/react/index.js");const r=function(e){var t=e.hMargin,n=e.dashboards,r=e.currentDashboard,s=e.loading,i=e.includeH1;return o.createElement("div",{className:"content-block__navigation",style:{marginLeft:t,marginRight:t}},o.createElement("div",{className:"content-block__navigation-left"},s?o.createElement("p",{className:"spinner"},o.createElement("i",{className:"fa fa-spinner fa-spin"})):null,o.createElement("div",{className:"list list--horizontal list--no-borders"},o.createElement("ul",{id:"menu_view",className:"list__items",role:"menu"},n.map((function(e,t){return o.createElement("li",{className:"list__item",key:t},function(e){return e.name===r.name?i?o.createElement("h1",null,o.createElement("span",{className:"link link--primary link--active"},e.name)):o.createElement("span",{className:"link link--primary link--active"},e.name):o.createElement("a",{className:"link link--primary",href:e.url},o.createElement("span",null,e.name))}(e))}))))))}},"./src/frontend/components/dashboard/lib/react/Widget.tsx":(e,t,n)=>{n.r(t),n.d(t,{default:()=>a});var o,r=n("./node_modules/react/index.js"),s=n("./src/frontend/js/lib/component.js"),i=(o=function(e,t){return o=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(e,t){e.__proto__=t}||function(e,t){for(var n in t)Object.prototype.hasOwnProperty.call(t,n)&&(e[n]=t[n])},o(e,t)},function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Class extends value "+String(t)+" is not a constructor or null");function n(){this.constructor=e}o(e,t),e.prototype=null===t?Object.create(t):(n.prototype=t.prototype,new n)});const a=function(e){function t(t){var n=e.call(this,t)||this;return n.shouldComponentUpdate=function(e){return e.widget.html!==n.props.widget.html},n.componentDidUpdate=function(){n.initializeLinkspace()},n.initializeLinkspace=function(){n.ref&&(0,s.initializeRegisteredComponents)(n.ref.current)},n.ref=r.createRef(),n}return i(t,e),t.prototype.render=function(){return r.createElement(r.Fragment,null,r.createElement("div",{ref:this.ref,dangerouslySetInnerHTML:{__html:this.props.widget.html}}),this.props.readOnly?null:r.createElement(r.Fragment,null,r.createElement("a",{className:"ld-edit-button",onClick:this.props.onEditClick},r.createElement("span",null,"edit widget")),r.createElement("span",{className:"ld-draggable-handle"},r.createElement("span",null,"drag widget"))))},t}(r.Component)},"./src/frontend/components/dashboard/lib/react/api.tsx":(e,t,n)=>{n.r(t),n.d(t,{default:()=>i});n("./node_modules/core-js/modules/es.object.assign.js"),n("./node_modules/core-js/modules/es.object.to-string.js"),n("./node_modules/core-js/modules/es.promise.js"),n("./node_modules/core-js/modules/es.symbol.js"),n("./node_modules/core-js/modules/es.symbol.description.js"),n("./node_modules/core-js/modules/es.symbol.iterator.js"),n("./node_modules/core-js/modules/es.array.iterator.js"),n("./node_modules/core-js/modules/es.string.iterator.js"),n("./node_modules/core-js/modules/web.dom-collections.iterator.js"),n("./node_modules/core-js/modules/es.array.map.js"),n("./node_modules/core-js/modules/es.array.concat.js"),n("./node_modules/core-js/modules/es.json.stringify.js");var o=function(){return o=Object.assign||function(e){for(var t,n=1,o=arguments.length;n<o;n++)for(var r in t=arguments[n])Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r]);return e},o.apply(this,arguments)},r=function(e,t,n,o){return new(n||(n=Promise))((function(r,s){function i(e){try{l(o.next(e))}catch(e){s(e)}}function a(e){try{l(o.throw(e))}catch(e){s(e)}}function l(e){var t;e.done?r(e.value):(t=e.value,t instanceof n?t:new n((function(e){e(t)}))).then(i,a)}l((o=o.apply(e,t||[])).next())}))},s=function(e,t){var n,o,r,s,i={label:0,sent:function(){if(1&r[0])throw r[1];return r[1]},trys:[],ops:[]};return s={next:a(0),throw:a(1),return:a(2)},"function"==typeof Symbol&&(s[Symbol.iterator]=function(){return this}),s;function a(s){return function(a){return function(s){if(n)throw new TypeError("Generator is already executing.");for(;i;)try{if(n=1,o&&(r=2&s[0]?o.return:s[0]?o.throw||((r=o.return)&&r.call(o),0):o.next)&&!(r=r.call(o,s[1])).done)return r;switch(o=0,r&&(s=[2&s[0],r.value]),s[0]){case 0:case 1:r=s;break;case 4:return i.label++,{value:s[1],done:!1};case 5:i.label++,o=s[1],s=[0];continue;case 7:s=i.ops.pop(),i.trys.pop();continue;default:if(!(r=i.trys,(r=r.length>0&&r[r.length-1])||6!==s[0]&&2!==s[0])){i=0;continue}if(3===s[0]&&(!r||s[1]>r[0]&&s[1]<r[3])){i.label=s[1];break}if(6===s[0]&&i.label<r[1]){i.label=r[1],r=s;break}if(r&&i.label<r[2]){i.label=r[2],i.ops.push(s);break}r[2]&&i.ops.pop(),i.trys.pop();continue}s=t.call(e,i)}catch(e){s=[6,e],o=0}finally{n=r=0}if(5&s[0])throw s[1];return{value:s[0]?s[1]:void 0,done:!0}}([s,a])}}};const i=function(){function e(e){void 0===e&&(e="");var t=this;this.saveLayout=function(e,n){if(!t.isDev){var r=n.map((function(e){return o(o({},e),{moved:void 0})}));return t.PUT("/dashboard/".concat(e),r)}},this.createWidget=function(e){return r(t,void 0,void 0,(function(){var t;return s(this,(function(n){switch(n.label){case 0:return this.isDev?[4,this.GET("/widget/create.json?type=".concat(e))]:[3,2];case 1:return t=n.sent(),[3,4];case 2:return[4,this.POST("/widget?type=".concat(e),null)];case 3:t=n.sent(),n.label=4;case 4:return[4,t.json()];case 5:return[2,n.sent()]}}))}))},this.getWidgetHtml=function(e){return r(t,void 0,void 0,(function(){var t;return s(this,(function(n){switch(n.label){case 0:return this.isDev?[4,this.GET("/widget/".concat(e,"/create"))]:[3,2];case 1:return t=n.sent(),[3,4];case 2:return[4,this.GET("/widget/".concat(e))];case 3:t=n.sent(),n.label=4;case 4:return[2,t.text()]}}))}))},this.deleteWidget=function(e){return!t.isDev&&t.DELETE("/widget/".concat(e))},this.getEditForm=function(e){return r(t,void 0,void 0,(function(){return s(this,(function(t){switch(t.label){case 0:return[4,this.GET("/widget/".concat(e,"/edit"))];case 1:return[2,t.sent().json()]}}))}))},this.saveWidget=function(e,n){return r(t,void 0,void 0,(function(){var t;return s(this,(function(o){switch(o.label){case 0:return this.isDev?[4,this.GET("/widget/update.json")]:[3,2];case 1:return t=o.sent(),[3,4];case 2:return[4,this.PUT("".concat(e,"?").concat(n),null)];case 3:t=o.sent(),o.label=4;case 4:return[4,t.json()];case 5:return[2,o.sent()]}}))}))},this.baseUrl=e,this.headers={},this.isDev=window.siteConfig&&window.siteConfig.isDev}return e.prototype._fetch=function(e,t,n){return r(this,void 0,void 0,(function(){var o,r,i,a,l;return s(this,(function(s){if(!e)throw new Error("Route is undefined");return o="","POST"!==t&&"PUT"!==t&&"PATCH"!==t&&"DELETE"!==t||(r=document.querySelector("body"),(i=r?r.getAttribute("data-csrf"):null)&&(o=e.indexOf("?")>-1?"&csrf-token=".concat(i):"?csrf-token=".concat(i))),a="".concat(this.baseUrl).concat(e).concat(o),l={method:t,headers:Object.assign(this.headers),credentials:"same-origin"},n&&(l.body=JSON.stringify(n)),[2,fetch(a,l)]}))}))},e.prototype.GET=function(e){return this._fetch(e,"GET",null)},e.prototype.POST=function(e,t){return this._fetch(e,"POST",t)},e.prototype.PUT=function(e,t){return this._fetch(e,"PUT",t)},e.prototype.PATCH=function(e,t){return this._fetch(e,"PATCH",t)},e.prototype.DELETE=function(e){return this._fetch(e,"DELETE",null)},e}()},"./src/frontend/components/dashboard/lib/react/app.tsx":(e,t,n)=>{n.r(t),n.d(t,{default:()=>O});n("./node_modules/core-js/modules/es.object.assign.js"),n("./node_modules/core-js/modules/es.object.to-string.js"),n("./node_modules/core-js/modules/es.promise.js"),n("./node_modules/core-js/modules/es.symbol.js"),n("./node_modules/core-js/modules/es.symbol.description.js"),n("./node_modules/core-js/modules/es.symbol.iterator.js"),n("./node_modules/core-js/modules/es.array.iterator.js"),n("./node_modules/core-js/modules/es.string.iterator.js"),n("./node_modules/core-js/modules/web.dom-collections.iterator.js"),n("./node_modules/core-js/modules/web.dom-collections.for-each.js"),n("./node_modules/core-js/modules/es.array.map.js"),n("./node_modules/core-js/modules/es.array.filter.js"),n("./node_modules/core-js/modules/es.array.concat.js"),n("./node_modules/core-js/modules/es.object.entries.js");var o=n("./node_modules/react/index.js"),r=n("./node_modules/form-serialize/index.js"),s=n.n(r),i=n("./node_modules/react-modal/lib/index.js"),a=n.n(i),l=n("./node_modules/react-grid-layout/index.js"),c=n.n(l),d=n("./src/frontend/components/dashboard/lib/react/Header.tsx"),u=n("./src/frontend/components/dashboard/lib/react/Widget.tsx"),m=n("./src/frontend/components/dashboard/lib/react/Footer.tsx"),f=n("./src/frontend/components/summernote/lib/component.js"),p=n("./src/frontend/components/globe/lib/component.js"),h=n("./src/frontend/components/sidebar/lib/sidebarObservable.js");function b(e){return b="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},b(e)}var g,y=(g=function(e,t){return g=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(e,t){e.__proto__=t}||function(e,t){for(var n in t)Object.prototype.hasOwnProperty.call(t,n)&&(e[n]=t[n])},g(e,t)},function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Class extends value "+String(t)+" is not a constructor or null");function n(){this.constructor=e}g(e,t),e.prototype=null===t?Object.create(t):(n.prototype=t.prototype,new n)}),v=function(){return v=Object.assign||function(e){for(var t,n=1,o=arguments.length;n<o;n++)for(var r in t=arguments[n])Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r]);return e},v.apply(this,arguments)},j=function(e,t,n,o){return new(n||(n=Promise))((function(r,s){function i(e){try{l(o.next(e))}catch(e){s(e)}}function a(e){try{l(o.throw(e))}catch(e){s(e)}}function l(e){var t;e.done?r(e.value):(t=e.value,t instanceof n?t:new n((function(e){e(t)}))).then(i,a)}l((o=o.apply(e,t||[])).next())}))},_=function(e,t){var n,o,r,s,i={label:0,sent:function(){if(1&r[0])throw r[1];return r[1]},trys:[],ops:[]};return s={next:a(0),throw:a(1),return:a(2)},"function"==typeof Symbol&&(s[Symbol.iterator]=function(){return this}),s;function a(s){return function(a){return function(s){if(n)throw new TypeError("Generator is already executing.");for(;i;)try{if(n=1,o&&(r=2&s[0]?o.return:s[0]?o.throw||((r=o.return)&&r.call(o),0):o.next)&&!(r=r.call(o,s[1])).done)return r;switch(o=0,r&&(s=[2&s[0],r.value]),s[0]){case 0:case 1:r=s;break;case 4:return i.label++,{value:s[1],done:!1};case 5:i.label++,o=s[1],s=[0];continue;case 7:s=i.ops.pop(),i.trys.pop();continue;default:if(!(r=i.trys,(r=r.length>0&&r[r.length-1])||6!==s[0]&&2!==s[0])){i=0;continue}if(3===s[0]&&(!r||s[1]>r[0]&&s[1]<r[3])){i.label=s[1];break}if(6===s[0]&&i.label<r[1]){i.label=r[1],r=s;break}if(r&&i.label<r[2]){i.label=r[2],i.ops.push(s);break}r[2]&&i.ops.pop(),i.trys.pop();continue}s=t.call(e,i)}catch(e){s=[6,e],o=0}finally{n=r=0}if(5&s[0])throw s[1];return{value:s[0]?s[1]:void 0,done:!0}}([s,a])}}},w=(0,l.WidthProvider)(c()),E={content:{minWidth:"350px",maxWidth:"80vw",maxHeight:"90vh",top:"50%",left:"50%",right:"auto",bottom:"auto",marginRight:"-50%",transform:"translate(-50%, -50%)",msTransform:"translate(-50%, -50%)",padding:0},overlay:{zIndex:1030,background:"rgba(0, 0, 0, .15)"}};const O=function(e){function t(t){var n=e.call(this,t)||this;n.componentDidMount=function(){n.initializeGlobeComponents()},n.componentDidUpdate=function(e,t){window.requestAnimationFrame(n.overWriteSubmitEventListener),n.state.editModalOpen&&t.loadingEditHtml&&!n.state.loadingEditHtml&&n.formRef&&n.initializeSummernoteComponent(),n.state.editModalOpen||t.loadingEditHtml||n.state.loadingEditHtml||n.initializeGlobeComponents()},n.initializeSummernoteComponent=function(){var e=n.formRef.current.querySelector(".summernote");if(e)new f.default(e)},n.initializeGlobeComponents=function(){document.querySelectorAll(".globe").forEach((function(e){new p.default(e)}))},n.updateWidgetHtml=function(e){return j(n,void 0,void 0,(function(){var t,n;return _(this,(function(o){switch(o.label){case 0:return[4,this.props.api.getWidgetHtml(e)];case 1:return t=o.sent(),n=this.state.widgets.map((function(n){return n.config.i===e?v(v({},n),{html:t}):n})),this.setState({widgets:n}),[2]}}))}))},n.fetchEditForm=function(e){return j(n,void 0,void 0,(function(){var t;return _(this,(function(n){switch(n.label){case 0:return[4,this.props.api.getEditForm(e)];case 1:return(t=n.sent()).is_error?(this.setState({loadingEditHtml:!1,editError:t.message}),[2]):(this.setState({loadingEditHtml:!1,editError:!1,editHtml:t.content}),[2])}}))}))},n.onEditClick=function(e){return function(t){t.preventDefault(),n.showEditForm(e)}},n.showEditForm=function(e){n.setState({editModalOpen:!0,loadingEditHtml:!0,activeItem:e}),n.fetchEditForm(e)},n.closeModal=function(){n.setState({editModalOpen:!1})},n.deleteActiveWidget=function(){window.confirm("Deleting a widget is permanent! Are you sure?")&&(n.setState({widgets:n.state.widgets.filter((function(e){return e.config.i!==n.state.activeItem})),editModalOpen:!1}),n.props.api.deleteWidget(n.state.activeItem))},n.saveActiveWidget=function(e){return j(n,void 0,void 0,(function(){var t,n,o;return _(this,(function(r){switch(r.label){case 0:return e.preventDefault(),(t=this.formRef.current.querySelector("form"))?(n=s()(t),[4,this.props.api.saveWidget(t.getAttribute("action"),n)]):(console.error("No form element was found!"),[2]);case 1:return(o=r.sent()).is_error?(this.setState({editError:o.message}),[2]):(this.updateWidgetHtml(this.state.activeItem),this.closeModal(),[2])}}))}))},n.isGridConflict=function(e,t,o,r){var s=e,i=t,a=e+o,l=t+r;return n.state.layout.some((function(e){return!(s>=e.x+e.w||e.x>=a)&&!(i>=e.y+e.h||e.y>=l)}))},n.firstAvailableSpot=function(e,t){for(var o=0,r=0;n.isGridConflict(o,r,e,t)&&(o+e<n.props.gridConfig.cols?o+=1:(o=0,r+=1),!(r>200)););return{x:o,y:r}},n.addWidget=function(e){return j(n,void 0,void 0,(function(){var t,n,o,r,s,i,a,l=this;return _(this,(function(c){switch(c.label){case 0:return this.setState({loading:!0}),[4,this.props.api.createWidget(e)];case 1:return(t=c.sent()).error?(this.setState({loading:!1}),alert(t.message),[2]):(n=t.message,o=this.firstAvailableSpot(1,1),r=o.x,s=o.y,i={i:n,x:r,y:s,w:1,h:1},a=this.state.layout.concat(i),this.setState({widgets:this.state.widgets.concat({config:i,html:"Loading..."}),layout:a,loading:!1},(function(){return l.updateWidgetHtml(n)})),this.props.api.saveLayout(this.props.dashboardId,a),this.showEditForm(n),[2])}}))}))},n.generateDOM=function(){return n.state.widgets.map((function(e){return o.createElement("div",{key:e.config.i,className:"ld-widget-container ".concat(n.props.readOnly||e.config.static?"":"ld-widget-container--editable")},o.createElement(u.default,{key:e.config.i,widget:e,readOnly:n.props.readOnly||e.config.static,onEditClick:n.onEditClick(e.config.i)}))}))},n.onLayoutChange=function(e){n.shouldSaveLayout(n.state.layout,e)&&n.props.api.saveLayout(n.props.dashboardId,e),n.setState({layout:e})},n.shouldSaveLayout=function(e,t){if(e.length!==t.length)return!0;for(var n=function(n){if(Object.entries(t[n]).some((function(t){var o=t[0],r=t[1];return"moved"!==o&&"static"!==o&&r!==e[n][o]})))return{value:!0}},o=0;o<e.length;o+=1){var r=n(o);if("object"===b(r))return r.value}return!1},n.renderModal=function(){return o.createElement(a(),{isOpen:n.state.editModalOpen,onRequestClose:n.closeModal,style:E,shouldCloseOnOverlayClick:!0,contentLabel:"Edit Modal"},o.createElement("div",{className:"modal-header"},o.createElement("div",{className:"modal-header__content"},o.createElement("h3",{className:"modal-title"},"Edit widget")),o.createElement("button",{className:"close",onClick:n.closeModal},o.createElement("span",{"aria-hidden":"true",className:"hidden"},"Close"))),o.createElement("div",{className:"modal-body"},n.state.editError?o.createElement("p",{className:"alert alert-danger"},n.state.editError):null,n.state.loadingEditHtml?o.createElement("span",{className:"ld-modal__loading"},"Loading..."):o.createElement("div",{ref:n.formRef,dangerouslySetInnerHTML:{__html:n.state.editHtml}})),o.createElement("div",{className:"modal-footer"},o.createElement("div",{className:"modal-footer__left"},o.createElement("button",{className:"btn btn-cancel",onClick:n.deleteActiveWidget},"Delete")),o.createElement("div",{className:"modal-footer__right"},o.createElement("button",{className:"btn btn-default",onClick:n.saveActiveWidget},"Save"))))},n.overWriteSubmitEventListener=function(){var e=document.getElementById("ld-form-container");if(e){var t=e.querySelector("form");if(t){t.addEventListener("submit",n.saveActiveWidget);var o=document.createElement("input");o.setAttribute("type","submit"),o.setAttribute("style","visibility: hidden"),t.appendChild(o)}}},n.handleSideBarChange=function(){window.dispatchEvent(new Event("resize"))},a().setAppElement("#ld-app");var r=t.widgets.map((function(e){return e.config}));return n.formRef=o.createRef(),h.sidebarObservable.addSubscriber(n),n.state={widgets:t.widgets,layout:r,editModalOpen:!1,activeItem:0,editHtml:"",editError:null,loading:!1,loadingEditHtml:!0},n}return y(t,e),t.prototype.render=function(){return o.createElement("div",{className:"content-block"},this.props.hideMenu?null:o.createElement(d.default,{hMargin:this.props.gridConfig.containerPadding[0],dashboards:this.props.dashboards,currentDashboard:this.props.currentDashboard,loading:this.state.loading,includeH1:this.props.includeH1}),this.renderModal(),o.createElement("div",{className:"content-block__main"},o.createElement(w,v({className:"content-block__main-content ".concat(this.props.readOnly?"":"react-grid-layout--editable"),isDraggable:!this.props.readOnly,isResizable:!this.props.readOnly,draggableHandle:".ld-draggable-handle",useCSSTransforms:!1,layout:this.state.layout,onLayoutChange:this.onLayoutChange,items:this.state.layout.length},this.props.gridConfig),this.generateDOM())),this.props.hideMenu?null:o.createElement(m.default,{addWidget:this.addWidget,widgetTypes:this.props.widgetTypes,currentDashboard:this.props.currentDashboard,noDownload:this.props.noDownload,readOnly:this.props.readOnly}))},t}(o.Component)},"./src/frontend/components/dashboard/lib/component.js":(e,t,n)=>{n.r(t),n.d(t,{default:()=>p});n("./node_modules/core-js/modules/es.array.slice.js"),n("./node_modules/core-js/modules/es.array.map.js"),n("./node_modules/core-js/modules/es.object.get-prototype-of.js"),n("./node_modules/core-js/modules/es.object.to-string.js"),n("./node_modules/core-js/modules/es.reflect.to-string-tag.js"),n("./node_modules/core-js/modules/es.reflect.construct.js"),n("./node_modules/core-js/modules/es.symbol.to-primitive.js"),n("./node_modules/core-js/modules/es.date.to-primitive.js"),n("./node_modules/core-js/modules/es.symbol.js"),n("./node_modules/core-js/modules/es.symbol.description.js"),n("./node_modules/core-js/modules/es.number.constructor.js"),n("./node_modules/core-js/modules/es.symbol.iterator.js"),n("./node_modules/core-js/modules/es.array.iterator.js"),n("./node_modules/core-js/modules/es.string.iterator.js"),n("./node_modules/core-js/modules/web.dom-collections.iterator.js");var o=n("./src/frontend/js/lib/component.js"),r=(n("./node_modules/react-app-polyfill/stable.js"),n("./node_modules/core-js/es/array/is-array.js"),n("./node_modules/core-js/es/map/index.js"),n("./node_modules/core-js/es/set/index.js"),n("./node_modules/core-js/es/object/define-property.js"),n("./node_modules/core-js/es/object/keys.js"),n("./node_modules/core-js/es/object/set-prototype-of.js"),n("./src/frontend/components/dashboard/lib/react/polyfills/classlist.js"),n("./node_modules/react/index.js")),s=n("./node_modules/react-dom/index.js"),i=n("./src/frontend/components/dashboard/lib/react/app.tsx"),a=n("./src/frontend/components/dashboard/lib/react/api.tsx"),l=n("./node_modules/jquery/dist/jquery.js");function c(e){return c="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},c(e)}function d(e,t){for(var n=0;n<t.length;n++){var o=t[n];o.enumerable=o.enumerable||!1,o.configurable=!0,"value"in o&&(o.writable=!0),Object.defineProperty(e,(r=o.key,s=void 0,s=function(e,t){if("object"!==c(e)||null===e)return e;var n=e[Symbol.toPrimitive];if(void 0!==n){var o=n.call(e,t||"default");if("object"!==c(o))return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(r,"string"),"symbol"===c(s)?s:String(s)),o)}var r,s}function u(e,t){return u=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(e,t){return e.__proto__=t,e},u(e,t)}function m(e){var t=function(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(e){return!1}}();return function(){var n,o=f(e);if(t){var r=f(this).constructor;n=Reflect.construct(o,arguments,r)}else n=o.apply(this,arguments);return function(e,t){if(t&&("object"===c(t)||"function"==typeof t))return t;if(void 0!==t)throw new TypeError("Derived constructors may only return object or undefined");return function(e){if(void 0===e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return e}(e)}(this,n)}}function f(e){return f=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(e){return e.__proto__||Object.getPrototypeOf(e)},f(e)}const p=function(e){!function(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function");e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,writable:!0,configurable:!0}}),Object.defineProperty(e,"prototype",{writable:!1}),t&&u(e,t)}(f,e);var t,n,o,c=m(f);function f(e){var t;return function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,f),(t=c.call(this,e)).el=l(t.element),t.gridConfig={cols:2,margin:[32,32],containerPadding:[0,10],rowHeight:80},t.initDashboard(),t}return t=f,(n=[{key:"initDashboard",value:function(){this.element.className="";var e=Array.prototype.slice.call(document.querySelectorAll("#ld-app > div")).map((function(e){return{html:e.innerHTML,config:JSON.parse(e.getAttribute("data-grid"))}})),t=new a.default(this.element.getAttribute("data-dashboard-endpoint")||"");s.render(r.createElement(i.default,{widgets:e,dashboardId:this.element.getAttribute("data-dashboard-id"),currentDashboard:JSON.parse(this.element.getAttribute("data-current-dashboard")||"{}"),readOnly:"true"===this.element.getAttribute("data-dashboard-read-only"),hideMenu:"true"===this.element.getAttribute("data-dashboard-hide-menu"),includeH1:"true"===this.element.getAttribute("data-dashboard-include-h1"),noDownload:"true"===this.element.getAttribute("data-dashboard-no-download"),api:t,widgetTypes:JSON.parse(this.element.getAttribute("data-widget-types")||"[]"),dashboards:JSON.parse(this.element.getAttribute("data-dashboards")||"[]"),gridConfig:this.gridConfig}),this.element)}}])&&d(t.prototype,n),o&&d(t,o),Object.defineProperty(t,"prototype",{writable:!1}),f}(o.Component)},"./src/frontend/components/dashboard/lib/react/polyfills/classlist.js":(e,t,n)=>{n.r(t);n("./node_modules/core-js/modules/es.string.trim.js"),n("./node_modules/core-js/modules/es.regexp.exec.js"),n("./node_modules/core-js/modules/es.string.replace.js"),n("./node_modules/core-js/modules/es.function.name.js"),n("./node_modules/core-js/modules/es.regexp.test.js"),n("./node_modules/core-js/modules/es.string.split.js"),n("./node_modules/core-js/modules/es.object.to-string.js"),n("./node_modules/core-js/modules/es.regexp.to-string.js"),n("./node_modules/core-js/modules/es.array.splice.js"),n("./node_modules/core-js/modules/es.array.join.js"),n("./node_modules/core-js/modules/es.object.define-getter.js");"document"in self&&((!("classList"in document.createElement("_"))||document.createElementNS&&!("classList"in document.createElementNS("http://www.w3.org/2000/svg","g")))&&function(e){if("Element"in e){var t="classList",n="prototype",o=e.Element[n],r=Object,s=String[n].trim||function(){return this.replace(/^\s+|\s+$/g,"")},i=Array[n].indexOf||function(e){for(var t=0,n=this.length;t<n;t++)if(t in this&&this[t]===e)return t;return-1},a=function(e,t){this.name=e,this.code=DOMException[e],this.message=t},l=function(e,t){if(""===t)throw new a("SYNTAX_ERR","An invalid or illegal string was specified");if(/\s/.test(t))throw new a("INVALID_CHARACTER_ERR","String contains an invalid character");return i.call(e,t)},c=function(e){for(var t=s.call(e.getAttribute("class")||""),n=t?t.split(/\s+/):[],o=0,r=n.length;o<r;o++)this.push(n[o]);this._updateClassName=function(){e.setAttribute("class",this.toString())}},d=c[n]=[],u=function(){return new c(this)};if(a[n]=Error[n],d.item=function(e){return this[e]||null},d.contains=function(e){return-1!==l(this,e+="")},d.add=function(){var e,t=arguments,n=0,o=t.length,r=!1;do{-1===l(this,e=t[n]+"")&&(this.push(e),r=!0)}while(++n<o);r&&this._updateClassName()},d.remove=function(){var e,t,n=arguments,o=0,r=n.length,s=!1;do{for(t=l(this,e=n[o]+"");-1!==t;)this.splice(t,1),s=!0,t=l(this,e)}while(++o<r);s&&this._updateClassName()},d.toggle=function(e,t){e+="";var n=this.contains(e),o=n?!0!==t&&"remove":!1!==t&&"add";return o&&this[o](e),!0===t||!1===t?t:!n},d.toString=function(){return this.join(" ")},r.defineProperty){var m={get:u,enumerable:!0,configurable:!0};try{r.defineProperty(o,t,m)}catch(e){void 0!==e.number&&-2146823252!==e.number||(m.enumerable=!1,r.defineProperty(o,t,m))}}else r[n].__defineGetter__&&o.__defineGetter__(t,u)}}(self),function(){var e=document.createElement("_");if(e.classList.add("c1","c2"),!e.classList.contains("c2")){var t=function(e){var t=DOMTokenList.prototype[e];DOMTokenList.prototype[e]=function(e){var n,o=arguments.length;for(n=0;n<o;n++)e=arguments[n],t.call(this,e)}};t("add"),t("remove")}if(e.classList.toggle("c3",!1),e.classList.contains("c3")){var n=DOMTokenList.prototype.toggle;DOMTokenList.prototype.toggle=function(e,t){return 1 in arguments&&!this.contains(e)==!t?t:n.call(this,e)}}e=null}())}}]);
//# sourceMappingURL=dashboard.ec1986b5acfcfa829f1b.js.map