"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[749],{28817:(t,e,a)=>{a.d(e,{A:()=>o});var i=a(17527),s=a(97468);class n{constructor(t,e){this.object=t,this.step=t.data("config").step,this.number=t.data("config").frame,this.item=t.data("config").item||null,this.skip=t.data("config").skip||null,this.back=e,this.requiredFields=t.find("input[required]"),this.isValid=!0,this.error=[],this.buttons={next:t.find(".modal-footer .btn-js-next"),back:t.find(".modal-footer .btn-js-back"),skip:t.find(".modal-footer .btn-js-skip"),addNext:t.find(".modal-footer .btn-js-add-next"),invisible:t.find(".modal-footer .btn-js-add-next"),save:t.find(".modal-footer .btn-js-save")}}}var r=a(11977),l=a(74692);class d extends i.uA{static get allowReinitialization(){return!0}constructor(t){super(t),this.el=l(this.element),this.isWizzard=this.el.hasClass("modal--wizzard"),this.isForm=this.el.hasClass("modal--form"),this.frames=this.el.find(".modal-frame"),this.typingTimer=null,this.wasInitialized||this.initModal()}initModal(){this.el.on("show.bs.modal",(()=>{if(s.y.addSubscriber(this),this.isWizzard){try{this.activateFrame(1,0)}catch(t){r.m.error(t),this.preventModalToOpen()}this.el.on("hide.bs.modal",(t=>{this.dataHasChanged()&&(confirm("Are you sure you want to close this popup? Any unsaved data will be lost.")||t.preventDefault())}))}(this.isWizzard||this.isForm)&&this.el.on("hidden.bs.modal",(()=>{this.el.off("hide.bs.modal"),s.y.close()})),this.hideContent(!0)}))}dataHasChanged(){const t=l(this.el).find("input, textarea");let e=!1;return t.each(((t,a)=>{if(l(a).val())if("hidden"!==l(a).attr("type")&&"checkbox"!==l(a).attr("type")&&"radio"!==l(a).attr("type")||"hidden"===l(a).attr("type")&&l(a).parents(".select").length){if(l(a).data("original-value")&&l(a).val().toString()!==l(a).data("original-value").toString()||!l(a).data("original-value"))return e=!0,!1}else if("hidden"!==l(a).attr("type")&&(l(a).data("original-value")&&l(a).prop("checked")&&l(a).val()!==l(a).data("original-value").toString()||!l(a).data("original-value")&&l(a).prop("checked")))return e=!0,!1})),e}hideContent(t){t?l("body").children().attr("aria-hidden",!0):l("body").children().removeAttr("aria-hidden")}preventModalToOpen(){const t=this.el.attr("id")||"";l(`.btn[data-target="#${t}"]`).on("click",(function(t){t.stopPropagation()}))}clearFields(t){l(t).find("input, textarea").each(((t,e)=>{const a=l(e);"radio"===a.attr("type")?a.prop("checked",!1):"checkbox"===a.attr("type")?a.is(":checked")&&a.trigger("click"):(a.data("restore-value")?a.val(a.data("restore-value")):a.val(""),l(e).removeData("original-value"),a.trigger("change")),a.is(":invalid")&&(a.attr("aria-invalid",!1),a.closest(".input").removeClass("input--invalid"))}))}clearFrames(t){t?l(t).each(((t,e)=>{const a=this.getFrameByNumber(e);a&&this.clearFields(a)})):this.frames.each(((t,e)=>{this.clearFields(e)}))}getFrameNumber(t){const e=l(t).data("config");if(e.frame&&!isNaN(e.frame))return e.frame}getFrameByNumber(t){let e=null;return this.frames.each(((a,i)=>{if(l(i).data("config").frame===t)return e=i,!1})),e}activateFrame(t,e,a){this.frames.each(((i,s)=>{const n=l(s).data("config");if(!n.frame||isNaN(n.frame))throw"activateFrame: frame is not a number!";if(this.unbindEventHandlers(l(s)),n.frame===t){try{this.frame=this.createFrame(s,e)}catch(t){r.m.error(t)}this.frame.object.removeClass("invisible"),this.frame.object.find(".alert").hide(),this.activateStep(this.frame.step),this.bindEventHandlers(),this.frame.requiredFields.length&&(this.frame.buttons.next&&this.setNextButtonState(!1),this.frame.buttons.invisible&&this.setInvisibleButtonState(!1)),a&&(this.clearFields(s),this.validateFrame())}else l(s).addClass("invisible")}))}createFrame(t,e){if(isNaN(l(t).data("config").step)||isNaN(l(t).data("config").frame))throw"createFrame: Parameter is not a number!";if(l(t).data("config").skip&&isNaN(l(t).data("config").skip))throw"createFrame: Skip parameter is not a number!";return new n(l(t),e)}bindEventHandlers(){this.frame.buttons.next.click((()=>{s.y.next(this.frame.object)})),this.frame.buttons.back.click((()=>{s.y.back(this.frame.object)})),this.frame.buttons.skip.click((()=>{this.frame.skip&&s.y.skip(this.frame.skip)})),this.frame.buttons.addNext.click((()=>{s.y.add(this.frame.object)})),this.frame.buttons.save.click((()=>{s.y.save()})),this.frame.requiredFields.bind("keyup.modalEvent",(t=>{this.handleKeyup(t)})),this.frame.requiredFields.bind("keydown.modalEvent",(()=>{this.handleKeydown()})),this.frame.requiredFields.bind("blur.modalEvent",(t=>{this.handleBlur(t)}))}handleKeyup(t){const e=t.target;clearTimeout(this.typingTimer),this.typingTimer=setTimeout((()=>{l(e).val()&&this.validateField(e)}),1e3)}handleKeydown(){clearTimeout(this.typingTimer)}handleBlur(t){const e=t.target;clearTimeout(this.typingTimer),l(e).val()&&this.validateField(e)}isValidField(t){return!l(t).is(":invalid")&&""!=l(t).val()}validateField(t){const e=this.isValidField(t);if(this.frame.error=[],!e){const e=l(t).closest(".input").find("label").html();this.frame.error.push(`${e} is invalid`)}this.setInputState(l(t),e),this.validateFrame()}validateFrame(){this.frame.isValid=!0,this.frame.requiredFields.each(((t,e)=>{this.isValidField(l(e))||(this.frame.isValid=!1)})),this.setFrameState()}setInputState(t){t.is(":invalid")?(t.attr("aria-invalid",!0),t.closest(".input").addClass("input--invalid")):(t.attr("aria-invalid",!1),t.closest(".input").removeClass("input--invalid"))}setFrameState(){const t=this.frame.object.find(".alert");if(this.frame.buttons.next&&this.setNextButtonState(this.frame.isValid),this.frame.buttons.invisible&&this.setInvisibleButtonState(this.frame.isValid),!this.frame.isValid&&this.frame.error.length>0){const e="<p>There were problems with the following fields:</p>";let a="";l.each(this.frame.error,((t,e)=>{const i=l("<span>").text(e).html();a+=`<li>${i}</li>`})),t.html(`<div>${e}<ul>${a}</ul></div>`),t.show(),this.el.animate({scrollTop:t.offset().top},500)}else t.hide()}unbindEventHandlers(t){t.find(".modal-footer .btn").unbind(),t.find("input[required]").unbind(".modalEvent")}setNextButtonState(t){t?(this.frame.buttons.next.removeAttr("disabled"),this.frame.buttons.next.removeClass("btn-disabled"),this.frame.buttons.next.addClass("btn-default")):(this.frame.buttons.next.attr("disabled","disabled"),this.frame.buttons.next.addClass("btn-disabled"),this.frame.buttons.next.removeClass("btn-default"))}setInvisibleButtonState(t){t?this.frame.buttons.invisible.removeClass("btn-invisible"):this.frame.buttons.invisible.addClass("btn-invisible")}activateStep(t){this.el.find(".modal__step").each(((e,a)=>{l(a).data("step")===t?l(a).addClass("modal__step--active"):l(a).removeClass("modal__step--active")}))}handleUpload(t){const e=this,a=this.el.data("config").url,i=this.el.data("config").id,s=l("body").data("csrf").toString();t.csrf_token=s||"";const n=JSON.stringify(t),r=i?`${a}/${i}`:a;l.ajax({method:"POST",contentType:"application/json",url:r,data:n,processData:!1}).done((function(){location.reload()})).fail((function(t){const a=t.responseJSON.message;e.showError(a)}))}showError(t){const e=this.frame.object.find(".alert"),a=l("<span>").text(t).html();e.html(`<p>Error: ${a}</p>`),e.show(),this.el.animate({scrollTop:e.offset().top},500)}handleNext(){const t=this.frame.number+1;this.frames.length>=t&&this.activateFrame(t,this.frame.number)}handleBack(){this.frame.back>0&&this.activateFrame(this.frame.back,this.frame.back-1),this.validateFrame()}handleSkip(t){this.activateFrame(t,this.frame.number)}handleAdd(t){s.y.update(t),this.clearFields(t),this.validateFrame()}handleActivate(t,e){this.activateFrame(t,this.frame.number,e)}handleShow(t){l(t).modal("show")}handleClear(t){this.clearFrames(t)}handleValidate(){this.validateFrame()}handleClose(){this.clearFrames(),this.isWizzard&&(this.activateFrame(1,0,!0),this.el.data("config")&&this.el.data("config").id&&(this.el.data("config").id=null)),this.el.unbind("hide.bs.modal hidden.bs.modal"),s.y.unsubscribe(this)}}const o=d},97468:(t,e,a)=>{a.d(e,{y:()=>i});const i=new class{constructor(){this.observers=[]}addSubscriber(t){this.observers.push(t)}unsubscribe(t){var e=this.observers.indexOf(t);this.observers.splice(e,1)}activate(t,e,a){this.observers.forEach((i=>i.handleActivate?.(t,e,a)))}add(t){this.observers.forEach((e=>e.handleAdd?.(t)))}back(t){this.observers.forEach((e=>e.handleBack?.(t)))}next(t){this.observers.forEach((e=>e.handleNext?.(t)))}show(t){this.observers.forEach((e=>e.handleShow?.(t)))}save(){this.observers.forEach((t=>t.handleSave?.()))}upload(t){this.observers.forEach((e=>e.handleUpload?.(t)))}clear(t){this.observers.forEach((e=>e.handleClear?.(t)))}close(){this.observers.forEach((t=>t.handleClose?.()))}skip(t){this.observers.forEach((e=>e.handleSkip?.(t)))}validate(){this.observers.forEach((t=>t.handleValidate?.()))}update(t){this.observers.forEach((e=>e.handleUpdate?.(t)))}}},15749:(t,e,a)=>{a.r(e),a.d(e,{default:()=>h});var i=a(28817),s=a(59888);const n=function(){var t=function(){return(65536*(1+Math.random())|0).toString(16).substring(1)};return t()+t()+"-"+t()+"-"+t()+"-"+t()+"-"+t()+t()+t()};var r=a(17527),l=a(56197),d=a(74692),o=a(74692);class c extends i.A{static get allowReinitialization(){return!0}constructor(t){super(t),this.context=void 0,this.wasInitialized||this.initCurvalModal()}initCurvalModal(){this.setupModal(),this.setupSubmit()}curvalModalValidationSucceeded(t,e){const i=t.serialize(),l=t.data("modal-field-ids"),c=t.data("curval-id"),h=t.data("instance-name");let u=t.data("guid");const m=d("<input>").attr({type:"hidden",name:"field"+c,value:i}),f=d("div[data-column-id="+c+"]");if("noshow"===f.data("value-selector")){const a=this,n=d('<tr class="table-curval-item">',a.context);o.map(l,(function(i){const r=t.find('[data-column-id="'+i+'"]');let l=(0,s.B)(r);l=e["field"+i],l=d("<div />",a.context).text(l).html(),n.append(d('<td class="curval-inner-text">',a.context).append(l))}));const f=d(`<td>\n          <button type="button" class="btn btn-small btn-link btn-js-curval-modal" data-toggle="modal" data-target="#curvalModal" data-layout-id="${c}" data-instance-name="${h}">\n            <span class="btn__title">Edit</span>\n          </button>\n          </td>`,this.context),b=d('<td>\n          <button type="button" class="btn btn-small btn-delete btn-js-curval-remove">\n            <span class="btn__title">Remove</span>\n          </button>\n        </td>',this.context);if(n.append(f.append(m)).append(b),(0,r.VZ)(n[0]),u){d('input[data-guid="'+u+'"]',this.context).val(i).closest(".table-curval-item").replaceWith(n)}else d(`#curval_list_${c}`).find("tbody").prepend(n),d(`#curval_list_${c}`).find(".dataTables_empty").hide()}else{const t=f.find(".select-widget").first(),s=t.hasClass("multi"),h=t.hasClass("select-widget--required"),m=f.find(".current"),b=m.find("[data-list-item]"),v=m.find(".search"),p=f.find(".available");s||(b.attr("hidden",""),p.find("li input").prop("checked",!1));const g=o.map(l,(function(t){const a=e["field"+t];return d("<div />").text(a).html()})).join(", ");u=n();const w=`field${c}_${u}`,y=s?'<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>':"";v.before(`<li data-list-item="${w}"><span class="widget-value__value">${g}</span>${y}</li>`).before(" ");const k=s?"checkbox":"radio",F=h?`required="required" aria-required="true" aria-errormessage="${t.attr("id")}-err"`:"";p.append(`<li class="answer" role="option">\n        <div class="control">\n          <div class="${s?"checkbox":"radio-group__option"}">\n            <input ${F} id="${w}" name="field${c}" type="${k}" value="${i}" class="${s?"":"radio-group__input"}" checked aria-labelledby="${w}_label">\n            <label id="${w}_label" for="${w}" class="${s?"":"radio-group__label"}">\n              <span>${g}</span>\n            </label>\n          </div>\n        </div>\n        <div class="details">\n          <button type="button" class="btn btn-small btn-danger btn-js-curval-remove">\n            <span class="btn__title">Remove</span>\n          </button>\n        </div>\n      </li>`),this.updateWidgetState(t,s,h),(0,r.VZ)(f[0]),a.e(732).then(a.bind(a,53163)).then((({default:e})=>{new e(t[0])}))}d(this.element).modal("hide")}updateWidgetState(t,e,a){const i=t.find(".current"),s=i.children("[data-list-item]:not([hidden])");i.toggleClass("empty",0===s.length),a&&(e?(0,l.dg)(t):(0,l.Px)(t))}curvalModalValidationFailed(t,e){t.find(".alert").text(e).removeAttr("hidden"),t.parents(".modal-content").get(0).scrollIntoView(),t.find("button[type=submit]").prop("disabled",!1)}setupModal(){this.el.on("show.bs.modal",(t=>{const e=t.relatedTarget,a=d(e).data("layout-id"),i=d(e).data("instance-name"),s=d(e).data("current-id"),l=d(e).closest(".table-curval-item").find(`input[name=field${a}]`),o=l.val(),c=l.length?"edit":"add",h=d(e).closest(".form-group");let u;h.find(".table-curval-group").length?this.context=h.find(".table-curval-group"):h.find(".select-widget").length&&(this.context=h.find(".select-widget")),"edit"===c&&(u=l.data("guid"),u||(u=n(),l.attr("data-guid",u)));const m=d(this.element),f=this;m.find(".modal-body").text("Loading...");const b=s?`/record/${s}`:`/${i}/record/`;m.find(".modal-body").load(this.getURL(b,a,o,h),(function(){"edit"===c&&m.find("form").data("guid",u),(0,r.VZ)(f.element)})),m.on("focus",".datepicker",(function(){d(this).datepicker({format:m.attr("data-dateformat-datepicker"),autoclose:!0})})),m.off("hide.bs.modal").on("hide.bs.modal",(()=>confirm("Closing this dialogue will cancel any work. Are you sure you want to do so?")))}))}getURL(t,e,a,i){return window.siteConfig&&window.siteConfig.urls.curvalTableForm&&window.siteConfig.urls.curvalSelectWidgetForm?"noshow"===i.data("value-selector")?window.siteConfig.urls.curvalTableForm:window.siteConfig.urls.curvalSelectWidgetForm:`${t}?include_draft&modal=${e}&${a}`}setupSubmit(){const t=this;d(this.element).on("submit",".curval-edit-form",(function(e){t.el.off("hide.bs.modal"),e.preventDefault();const a=d(this),i=a.serialize();a.addClass("edit-form--validating"),a.find(".alert").attr("hidden","");const s=window.siteConfig&&window.siteConfig.curvalData;s?t.curvalModalValidationSucceeded(a,s.values):d.post(a.attr("action")+"?validate&include_draft&source="+a.data("curval-id"),i,(function(e){if(0===e.error)t.curvalModalValidationSucceeded(a,e.values);else{const i=1===e.error?e.message:"Oops! Something went wrong.";t.curvalModalValidationFailed(a,i)}}),"json").fail((function(e,i,s){const n=`Oops! Something went wrong: ${i}: ${s}`;t.curvalModalValidationFailed(a,n)})).always((function(){a.removeClass("edit-form--validating")}))}))}}const h=c}}]);