"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[683],{40721:(e,o,n)=>{n.r(o),n.d(o,{default:()=>d});n(25728),n(60228);var t=n(19755);function d(e){e.on("click",(function(e){var o=t(e.target).closest(".btn"),n=o.data("record-id"),d=o.data("target"),a=t(document).find(d);a.find(".modal-title").text("Record ID: ".concat(n)),a.find(".modal-body").text("Loading..."),a.find(".modal-body").load("/record_body/"+n),a.one("show.bs.modal",(function(e){e.isDefaultPrevented()||a.one("hidden.bs.modal",(function(){o.is(":visible")&&o.trigger("focus")}))})),a.one("keyup",(function(e){"Escape"===e.key&&e.stopPropagation()}))}))}}}]);