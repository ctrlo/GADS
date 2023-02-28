"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[966],{22462:(t,e,n)=>{n.r(e),n.d(e,{default:()=>W});n(47042),n(21249),n(30489),n(41539),n(81299),n(12419),n(96649),n(96078),n(82526),n(41817),n(9653),n(32165),n(66992),n(78783),n(33948);var r=n(53865);n(32377),n(11414),n(63662),n(88188),n(24678),n(61514),n(26017),n(73210),n(74916),n(15306),n(68309),n(77601),n(23123),n(39714),n(40561),n(69600),n(59595);"document"in self&&((!("classList"in document.createElement("_"))||document.createElementNS&&!("classList"in document.createElementNS("http://www.w3.org/2000/svg","g")))&&function(t){if("Element"in t){var e="classList",n="prototype",r=t.Element[n],i=Object,o=String[n].trim||function(){return this.replace(/^\s+|\s+$/g,"")},a=Array[n].indexOf||function(t){for(var e=0,n=this.length;e<n;e++)if(e in this&&this[e]===t)return e;return-1},s=function(t,e){this.name=t,this.code=DOMException[t],this.message=e},l=function(t,e){if(""===e)throw new s("SYNTAX_ERR","An invalid or illegal string was specified");if(/\s/.test(e))throw new s("INVALID_CHARACTER_ERR","String contains an invalid character");return a.call(t,e)},c=function(t){for(var e=o.call(t.getAttribute("class")||""),n=e?e.split(/\s+/):[],r=0,i=n.length;r<i;r++)this.push(n[r]);this._updateClassName=function(){t.setAttribute("class",this.toString())}},u=c[n]=[],d=function(){return new c(this)};if(s[n]=Error[n],u.item=function(t){return this[t]||null},u.contains=function(t){return-1!==l(this,t+="")},u.add=function(){var t,e=arguments,n=0,r=e.length,i=!1;do{-1===l(this,t=e[n]+"")&&(this.push(t),i=!0)}while(++n<r);i&&this._updateClassName()},u.remove=function(){var t,e,n=arguments,r=0,i=n.length,o=!1;do{for(e=l(this,t=n[r]+"");-1!==e;)this.splice(e,1),o=!0,e=l(this,t)}while(++r<i);o&&this._updateClassName()},u.toggle=function(t,e){t+="";var n=this.contains(t),r=n?!0!==e&&"remove":!1!==e&&"add";return r&&this[r](t),!0===e||!1===e?e:!n},u.toString=function(){return this.join(" ")},i.defineProperty){var f={get:d,enumerable:!0,configurable:!0};try{i.defineProperty(r,e,f)}catch(t){void 0!==t.number&&-2146823252!==t.number||(f.enumerable=!1,i.defineProperty(r,e,f))}}else i[n].__defineGetter__&&r.__defineGetter__(e,d)}}(self),function(){var t=document.createElement("_");if(t.classList.add("c1","c2"),!t.classList.contains("c2")){var e=function(t){var e=DOMTokenList.prototype[t];DOMTokenList.prototype[t]=function(t){var n,r=arguments.length;for(n=0;n<r;n++)t=arguments[n],e.call(this,t)}};e("add"),e("remove")}if(t.classList.toggle("c3",!1),t.classList.contains("c3")){var n=DOMTokenList.prototype.toggle;DOMTokenList.prototype.toggle=function(t,e){return 1 in arguments&&!this.contains(t)==!e?e:n.call(this,t)}}t=null}());var i=n(67294),o=n(73935),a=(n(19601),n(88674),n(54747),n(57327),n(92222),n(69720),n(7422)),s=n.n(a),l=n(83253),c=n.n(l),u=n(69968),d=n.n(u);const f=function(t){var e=t.hMargin,n=t.dashboards,r=t.currentDashboard,o=t.loading;return i.createElement("div",{className:"content-block__navigation",style:{marginLeft:e,marginRight:e}},i.createElement("div",{className:"content-block__navigation-left"},o?i.createElement("p",{className:"spinner"},i.createElement("i",{className:"fa fa-spinner fa-spin"})):null,i.createElement("div",{className:"list list--horizontal list--no-borders"},i.createElement("ul",{id:"menu_view",className:"list__items",role:"menu"},n.map((function(t,e){return i.createElement("li",{className:"list__item",key:e},function(t){return t.name===r.name?i.createElement("span",{className:"link link--primary link--active"},t.name):i.createElement("a",{className:"link link--primary",href:t.url},i.createElement("span",null,t.name))}(t))}))))))};var p,m=(p=function(t,e){return p=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(t,e){t.__proto__=e}||function(t,e){for(var n in e)Object.prototype.hasOwnProperty.call(e,n)&&(t[n]=e[n])},p(t,e)},function(t,e){if("function"!=typeof e&&null!==e)throw new TypeError("Class extends value "+String(e)+" is not a constructor or null");function n(){this.constructor=t}p(t,e),t.prototype=null===e?Object.create(e):(n.prototype=e.prototype,new n)});const h=function(t){function e(e){var n=t.call(this,e)||this;return n.shouldComponentUpdate=function(t){return t.widget.html!==n.props.widget.html},n.componentDidUpdate=function(){n.initializeLinkspace()},n.initializeLinkspace=function(){n.ref&&(0,r.ez)(n.ref.current)},n.ref=i.createRef(),n}return m(e,t),e.prototype.render=function(){return i.createElement(i.Fragment,null,i.createElement("div",{ref:this.ref,dangerouslySetInnerHTML:{__html:this.props.widget.html}}),this.props.readOnly?null:i.createElement(i.Fragment,null,i.createElement("a",{className:"ld-edit-button",onClick:this.props.onEditClick},i.createElement("span",null,"edit widget")),i.createElement("span",{className:"ld-draggable-handle"},i.createElement("span",null,"drag widget"))))},e}(i.Component);const g=function(t){var e=t.addWidget,n=t.widgetTypes,r=t.currentDashboard,o=t.readOnly,a=t.noDownload;return i.createElement("div",{className:"ld-footer-container"},a?null:i.createElement("div",{className:"btn-group mb-3 mb-md-0 mr-md-4"},i.createElement("button",{type:"button",className:"btn btn-default dropdown-toggle","data-toggle":"dropdown","aria-expanded":"false","aria-controls":"menu_view"},"Download ",i.createElement("span",{className:"caret"})),i.createElement("div",{className:"dropdown-menu dropdown__menu dropdown-menu-right scrollable-menu",role:"menu"},i.createElement("ul",{id:"menu_view",className:"dropdown__list"},i.createElement("li",{className:"dropdown__item"},i.createElement("a",{className:"link link--plain",href:r.download_url},"As PDF"))))),o?null:i.createElement("div",{className:"btn-group"},i.createElement("button",{type:"button",className:"btn btn-default dropdown-toggle","data-toggle":"dropdown","aria-expanded":"false","aria-controls":"menu_view"},"Add Widget"),i.createElement("div",{className:"dropdown-menu dropdown__menu dropdown-menu-right scrollable-menu",role:"menu"},i.createElement("ul",{id:"menu_view",className:"dropdown__list"},n.map((function(t){return i.createElement("li",{key:t,className:"dropdown__item"},i.createElement("a",{className:"link link--plain",href:"#",onClick:function(n){n.preventDefault(),e(t)}},t))}))))))};var y=n(67714),b=n(12192);function v(t){return v="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},v(t)}var w=function(){var t=function(e,n){return t=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(t,e){t.__proto__=e}||function(t,e){for(var n in e)Object.prototype.hasOwnProperty.call(e,n)&&(t[n]=e[n])},t(e,n)};return function(e,n){if("function"!=typeof n&&null!==n)throw new TypeError("Class extends value "+String(n)+" is not a constructor or null");function r(){this.constructor=e}t(e,n),e.prototype=null===n?Object.create(n):(r.prototype=n.prototype,new r)}}(),E=function(){return E=Object.assign||function(t){for(var e,n=1,r=arguments.length;n<r;n++)for(var i in e=arguments[n])Object.prototype.hasOwnProperty.call(e,i)&&(t[i]=e[i]);return t},E.apply(this,arguments)},_=function(t,e,n,r){return new(n||(n=Promise))((function(i,o){function a(t){try{l(r.next(t))}catch(t){o(t)}}function s(t){try{l(r.throw(t))}catch(t){o(t)}}function l(t){var e;t.done?i(t.value):(e=t.value,e instanceof n?e:new n((function(t){t(e)}))).then(a,s)}l((r=r.apply(t,e||[])).next())}))},O=function(t,e){var n,r,i,o,a={label:0,sent:function(){if(1&i[0])throw i[1];return i[1]},trys:[],ops:[]};return o={next:s(0),throw:s(1),return:s(2)},"function"==typeof Symbol&&(o[Symbol.iterator]=function(){return this}),o;function s(o){return function(s){return function(o){if(n)throw new TypeError("Generator is already executing.");for(;a;)try{if(n=1,r&&(i=2&o[0]?r.return:o[0]?r.throw||((i=r.return)&&i.call(r),0):r.next)&&!(i=i.call(r,o[1])).done)return i;switch(r=0,i&&(o=[2&o[0],i.value]),o[0]){case 0:case 1:i=o;break;case 4:return a.label++,{value:o[1],done:!1};case 5:a.label++,r=o[1],o=[0];continue;case 7:o=a.ops.pop(),a.trys.pop();continue;default:if(!(i=a.trys,(i=i.length>0&&i[i.length-1])||6!==o[0]&&2!==o[0])){a=0;continue}if(3===o[0]&&(!i||o[1]>i[0]&&o[1]<i[3])){a.label=o[1];break}if(6===o[0]&&a.label<i[1]){a.label=i[1],i=o;break}if(i&&a.label<i[2]){a.label=i[2],a.ops.push(o);break}i[2]&&a.ops.pop(),a.trys.pop();continue}o=e.call(t,a)}catch(t){o=[6,t],r=0}finally{n=i=0}if(5&o[0])throw o[1];return{value:o[0]?o[1]:void 0,done:!0}}([o,s])}}},S=(0,u.WidthProvider)(d()),N={content:{minWidth:"350px",maxWidth:"80vw",maxHeight:"90vh",top:"50%",left:"50%",right:"auto",bottom:"auto",marginRight:"-50%",transform:"translate(-50%, -50%)",msTransform:"translate(-50%, -50%)",padding:0},overlay:{zIndex:1030,background:"rgba(0, 0, 0, .15)"}};const k=function(t){function e(e){var n=t.call(this,e)||this;n.componentDidMount=function(){n.initializeGlobeComponents()},n.componentDidUpdate=function(t,e){window.requestAnimationFrame(n.overWriteSubmitEventListener),n.state.editModalOpen&&e.loadingEditHtml&&!n.state.loadingEditHtml&&n.formRef&&n.initializeSummernoteComponent(),n.state.editModalOpen||e.loadingEditHtml||n.state.loadingEditHtml||n.initializeGlobeComponents()},n.initializeSummernoteComponent=function(){var t=n.formRef.current.querySelector(".summernote");if(t)new y.Z(t)},n.initializeGlobeComponents=function(){document.querySelectorAll(".globe").forEach((function(t){new b.default(t)}))},n.updateWidgetHtml=function(t){return _(n,void 0,void 0,(function(){var e,n;return O(this,(function(r){switch(r.label){case 0:return[4,this.props.api.getWidgetHtml(t)];case 1:return e=r.sent(),n=this.state.widgets.map((function(n){return n.config.i===t?E(E({},n),{html:e}):n})),this.setState({widgets:n}),[2]}}))}))},n.fetchEditForm=function(t){return _(n,void 0,void 0,(function(){var e;return O(this,(function(n){switch(n.label){case 0:return[4,this.props.api.getEditForm(t)];case 1:return(e=n.sent()).is_error?(this.setState({loadingEditHtml:!1,editError:e.message}),[2]):(this.setState({loadingEditHtml:!1,editError:!1,editHtml:e.content}),[2])}}))}))},n.onEditClick=function(t){return function(e){e.preventDefault(),n.showEditForm(t)}},n.showEditForm=function(t){n.setState({editModalOpen:!0,loadingEditHtml:!0,activeItem:t}),n.fetchEditForm(t)},n.closeModal=function(){n.setState({editModalOpen:!1})},n.deleteActiveWidget=function(){window.confirm("Deleting a widget is permanent! Are you sure?")&&(n.setState({widgets:n.state.widgets.filter((function(t){return t.config.i!==n.state.activeItem})),editModalOpen:!1}),n.props.api.deleteWidget(n.state.activeItem))},n.saveActiveWidget=function(t){return _(n,void 0,void 0,(function(){var e,n,r;return O(this,(function(i){switch(i.label){case 0:return t.preventDefault(),(e=this.formRef.current.querySelector("form"))?(n=s()(e),[4,this.props.api.saveWidget(e.getAttribute("action"),n)]):(console.error("No form element was found!"),[2]);case 1:return(r=i.sent()).is_error?(this.setState({editError:r.message}),[2]):(this.updateWidgetHtml(this.state.activeItem),this.closeModal(),[2])}}))}))},n.isGridConflict=function(t,e,r,i){var o=t,a=e,s=t+r,l=e+i;return n.state.layout.some((function(t){return!(o>=t.x+t.w||t.x>=s)&&!(a>=t.y+t.h||t.y>=l)}))},n.firstAvailableSpot=function(t,e){for(var r=0,i=0;n.isGridConflict(r,i,t,e)&&(r+t<n.props.gridConfig.cols?r+=1:(r=0,i+=1),!(i>200)););return{x:r,y:i}},n.addWidget=function(t){return _(n,void 0,void 0,(function(){var e,n,r,i,o,a,s,l=this;return O(this,(function(c){switch(c.label){case 0:return this.setState({loading:!0}),[4,this.props.api.createWidget(t)];case 1:return(e=c.sent()).error?(this.setState({loading:!1}),alert(e.message),[2]):(n=e.message,r=this.firstAvailableSpot(1,1),i=r.x,o=r.y,a={i:n,x:i,y:o,w:1,h:1},s=this.state.layout.concat(a),this.setState({widgets:this.state.widgets.concat({config:a,html:"Loading..."}),layout:s,loading:!1},(function(){return l.updateWidgetHtml(n)})),this.props.api.saveLayout(this.props.dashboardId,s),this.showEditForm(n),[2])}}))}))},n.generateDOM=function(){return n.state.widgets.map((function(t){return i.createElement("div",{key:t.config.i,className:"ld-widget-container ".concat(n.props.readOnly||t.config.static?"":"ld-widget-container--editable")},i.createElement(h,{key:t.config.i,widget:t,readOnly:n.props.readOnly||t.config.static,onEditClick:n.onEditClick(t.config.i)}))}))},n.onLayoutChange=function(t){n.shouldSaveLayout(n.state.layout,t)&&n.props.api.saveLayout(n.props.dashboardId,t),n.setState({layout:t})},n.shouldSaveLayout=function(t,e){if(t.length!==e.length)return!0;for(var n=function(n){if(Object.entries(e[n]).some((function(e){var r=e[0],i=e[1];return"moved"!==r&&"static"!==r&&i!==t[n][r]})))return{value:!0}},r=0;r<t.length;r+=1){var i=n(r);if("object"===v(i))return i.value}return!1},n.renderModal=function(){return i.createElement(c(),{isOpen:n.state.editModalOpen,onRequestClose:n.closeModal,style:N,shouldCloseOnOverlayClick:!0,contentLabel:"Edit Modal"},i.createElement("div",{className:"modal-header"},i.createElement("div",{className:"modal-header__content"},i.createElement("h3",{className:"modal-title"},"Edit widget")),i.createElement("button",{className:"close",onClick:n.closeModal},i.createElement("span",{"aria-hidden":"true",className:"hidden"},"Close"))),i.createElement("div",{className:"modal-body"},n.state.editError?i.createElement("p",{className:"alert alert-danger"},n.state.editError):null,n.state.loadingEditHtml?i.createElement("span",{className:"ld-modal__loading"},"Loading..."):i.createElement("div",{ref:n.formRef,dangerouslySetInnerHTML:{__html:n.state.editHtml}})),i.createElement("div",{className:"modal-footer"},i.createElement("div",{className:"modal-footer__left"},i.createElement("button",{className:"btn btn-cancel",onClick:n.deleteActiveWidget},"Delete")),i.createElement("div",{className:"modal-footer__right"},i.createElement("button",{className:"btn btn-default",onClick:n.saveActiveWidget},"Save"))))},n.overWriteSubmitEventListener=function(){var t=document.getElementById("ld-form-container");if(t){var e=t.querySelector("form");if(e){e.addEventListener("submit",n.saveActiveWidget);var r=document.createElement("input");r.setAttribute("type","submit"),r.setAttribute("style","visibility: hidden"),e.appendChild(r)}}},c().setAppElement("#ld-app");var r=e.widgets.map((function(t){return t.config}));return n.formRef=i.createRef(),n.state={widgets:e.widgets,layout:r,editModalOpen:!1,activeItem:0,editHtml:"",editError:null,loading:!1,loadingEditHtml:!0},n}return w(e,t),e.prototype.render=function(){return i.createElement("div",{className:"content-block"},this.props.hideMenu?null:i.createElement(f,{hMargin:this.props.gridConfig.containerPadding[0],dashboards:this.props.dashboards,currentDashboard:this.props.currentDashboard,loading:this.state.loading}),this.renderModal(),i.createElement("div",{className:"content-block__main"},i.createElement(S,E({className:"content-block__main-content ".concat(this.props.readOnly?"":"react-grid-layout--editable"),isDraggable:!this.props.readOnly,isResizable:!this.props.readOnly,draggableHandle:".ld-draggable-handle",useCSSTransforms:!1,layout:this.state.layout,onLayoutChange:this.onLayoutChange,items:this.state.layout.length},this.props.gridConfig),this.generateDOM())),this.props.hideMenu?null:i.createElement(g,{addWidget:this.addWidget,widgetTypes:this.props.widgetTypes,currentDashboard:this.props.currentDashboard,noDownload:this.props.noDownload,readOnly:this.props.readOnly}))},e}(i.Component);n(38862);var C=function(){return C=Object.assign||function(t){for(var e,n=1,r=arguments.length;n<r;n++)for(var i in e=arguments[n])Object.prototype.hasOwnProperty.call(e,i)&&(t[i]=e[i]);return t},C.apply(this,arguments)},T=function(t,e,n,r){return new(n||(n=Promise))((function(i,o){function a(t){try{l(r.next(t))}catch(t){o(t)}}function s(t){try{l(r.throw(t))}catch(t){o(t)}}function l(t){var e;t.done?i(t.value):(e=t.value,e instanceof n?e:new n((function(t){t(e)}))).then(a,s)}l((r=r.apply(t,e||[])).next())}))},D=function(t,e){var n,r,i,o,a={label:0,sent:function(){if(1&i[0])throw i[1];return i[1]},trys:[],ops:[]};return o={next:s(0),throw:s(1),return:s(2)},"function"==typeof Symbol&&(o[Symbol.iterator]=function(){return this}),o;function s(o){return function(s){return function(o){if(n)throw new TypeError("Generator is already executing.");for(;a;)try{if(n=1,r&&(i=2&o[0]?r.return:o[0]?r.throw||((i=r.return)&&i.call(r),0):r.next)&&!(i=i.call(r,o[1])).done)return i;switch(r=0,i&&(o=[2&o[0],i.value]),o[0]){case 0:case 1:i=o;break;case 4:return a.label++,{value:o[1],done:!1};case 5:a.label++,r=o[1],o=[0];continue;case 7:o=a.ops.pop(),a.trys.pop();continue;default:if(!(i=a.trys,(i=i.length>0&&i[i.length-1])||6!==o[0]&&2!==o[0])){a=0;continue}if(3===o[0]&&(!i||o[1]>i[0]&&o[1]<i[3])){a.label=o[1];break}if(6===o[0]&&a.label<i[1]){a.label=i[1],i=o;break}if(i&&a.label<i[2]){a.label=i[2],a.ops.push(o);break}i[2]&&a.ops.pop(),a.trys.pop();continue}o=e.call(t,a)}catch(t){o=[6,t],r=0}finally{n=i=0}if(5&o[0])throw o[1];return{value:o[0]?o[1]:void 0,done:!0}}([o,s])}}};const A=function(){function t(t){void 0===t&&(t="");var e=this;this.saveLayout=function(t,n){if(!e.isDev){var r=n.map((function(t){return C(C({},t),{moved:void 0})}));return e.PUT("/dashboard/".concat(t),r)}},this.createWidget=function(t){return T(e,void 0,void 0,(function(){var e;return D(this,(function(n){switch(n.label){case 0:return this.isDev?[4,this.GET("/widget/create.json?type=".concat(t))]:[3,2];case 1:return e=n.sent(),[3,4];case 2:return[4,this.POST("/widget?type=".concat(t),null)];case 3:e=n.sent(),n.label=4;case 4:return[4,e.json()];case 5:return[2,n.sent()]}}))}))},this.getWidgetHtml=function(t){return T(e,void 0,void 0,(function(){var e;return D(this,(function(n){switch(n.label){case 0:return this.isDev?[4,this.GET("/widget/".concat(t,"/create"))]:[3,2];case 1:return e=n.sent(),[3,4];case 2:return[4,this.GET("/widget/".concat(t))];case 3:e=n.sent(),n.label=4;case 4:return[2,e.text()]}}))}))},this.deleteWidget=function(t){return!e.isDev&&e.DELETE("/widget/".concat(t))},this.getEditForm=function(t){return T(e,void 0,void 0,(function(){return D(this,(function(e){switch(e.label){case 0:return[4,this.GET("/widget/".concat(t,"/edit"))];case 1:return[2,e.sent().json()]}}))}))},this.saveWidget=function(t,n){return T(e,void 0,void 0,(function(){var e;return D(this,(function(r){switch(r.label){case 0:return this.isDev?[4,this.GET("/widget/update.json")]:[3,2];case 1:return e=r.sent(),[3,4];case 2:return[4,this.PUT("".concat(t,"?").concat(n),null)];case 3:e=r.sent(),r.label=4;case 4:return[4,e.json()];case 5:return[2,r.sent()]}}))}))},this.baseUrl=t,this.headers={},this.isDev=window.siteConfig&&window.siteConfig.isDev}return t.prototype._fetch=function(t,e,n){return T(this,void 0,void 0,(function(){var r,i,o,a,s;return D(this,(function(l){if(!t)throw new Error("Route is undefined");return r="","POST"!==e&&"PUT"!==e&&"PATCH"!==e&&"DELETE"!==e||(i=document.querySelector("body"),(o=i?i.getAttribute("data-csrf"):null)&&(r=t.indexOf("?")>-1?"&csrf-token=".concat(o):"?csrf-token=".concat(o))),a="".concat(this.baseUrl).concat(t).concat(r),s={method:e,headers:Object.assign(this.headers),credentials:"same-origin"},n&&(s.body=JSON.stringify(n)),[2,fetch(a,s)]}))}))},t.prototype.GET=function(t){return this._fetch(t,"GET",null)},t.prototype.POST=function(t,e){return this._fetch(t,"POST",e)},t.prototype.PUT=function(t,e){return this._fetch(t,"PUT",e)},t.prototype.PATCH=function(t,e){return this._fetch(t,"PATCH",e)},t.prototype.DELETE=function(t){return this._fetch(t,"DELETE",null)},t}();var P=n(19755);function L(t){return L="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},L(t)}function j(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(i=r.key,o=void 0,o=function(t,e){if("object"!==L(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==L(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(i,"string"),"symbol"===L(o)?o:String(o)),r)}var i,o}function M(t,e){return M=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(t,e){return t.__proto__=e,t},M(t,e)}function x(t){var e=function(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(t){return!1}}();return function(){var n,r=H(t);if(e){var i=H(this).constructor;n=Reflect.construct(r,arguments,i)}else n=r.apply(this,arguments);return function(t,e){if(e&&("object"===L(e)||"function"==typeof e))return e;if(void 0!==e)throw new TypeError("Derived constructors may only return object or undefined");return function(t){if(void 0===t)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return t}(t)}(this,n)}}function H(t){return H=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(t){return t.__proto__||Object.getPrototypeOf(t)},H(t)}const W=function(t){!function(t,e){if("function"!=typeof e&&null!==e)throw new TypeError("Super expression must either be null or a function");t.prototype=Object.create(e&&e.prototype,{constructor:{value:t,writable:!0,configurable:!0}}),Object.defineProperty(t,"prototype",{writable:!1}),e&&M(t,e)}(s,t);var e,n,r,a=x(s);function s(t){var e;return function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,s),(e=a.call(this,t)).el=P(e.element),e.gridConfig={cols:2,margin:[32,32],containerPadding:[0,10],rowHeight:80},e.initDashboard(),e}return e=s,(n=[{key:"initDashboard",value:function(){this.element.className="";var t=Array.prototype.slice.call(document.querySelectorAll("#ld-app > div")).map((function(t){return{html:t.innerHTML,config:JSON.parse(t.getAttribute("data-grid"))}})),e=new A(this.element.getAttribute("data-dashboard-endpoint")||"");o.render(i.createElement(k,{widgets:t,dashboardId:this.element.getAttribute("data-dashboard-id"),currentDashboard:JSON.parse(this.element.getAttribute("data-current-dashboard")||"{}"),readOnly:"true"===this.element.getAttribute("data-dashboard-read-only"),hideMenu:"true"===this.element.getAttribute("data-dashboard-hide-menu"),noDownload:"true"===this.element.getAttribute("data-dashboard-no-download"),api:e,widgetTypes:JSON.parse(this.element.getAttribute("data-widget-types")||"[]"),dashboards:JSON.parse(this.element.getAttribute("data-dashboards")||"[]"),gridConfig:this.gridConfig}),this.element)}}])&&j(e.prototype,n),r&&j(e,r),Object.defineProperty(e,"prototype",{writable:!1}),s}(r.wA)}}]);