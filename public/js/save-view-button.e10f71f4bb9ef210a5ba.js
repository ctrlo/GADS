"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[363],{59050:(e,t,r)=>{r.r(t),r.d(t,{default:()=>s});var l=r(56197),a=(r(99893),r(74692));function s(e){const t=e.closest("form"),r=t.find("#global"),s=t.find(".select.dropdown");r.on("change",(e=>{const r=t.find("input[type=hidden][name=group_id]");e.target?.checked?(r.attr("required","required"),s&&s.attr&&s.attr("placeholder")&&s.attr("placeholder").match(/All [Uu]sers/)&&s.addClass("select--required")):(r.removeAttr("required"),s&&s.attr&&s.attr("placeholder")&&s.attr("placeholder").match(/All [Uu]sers/)&&s.removeClass("select--required"))})),e.on("click",(e=>{const t=a(e.target).closest("form");(0,l.Rv)(t)||e.preventDefault();const r=t.find("input[type=hidden][name=group_id]");"allusers"===r.val()&&(r.val(""),r.removeAttr("required")),a(".filter").each(((t,r)=>{a(r).queryBuilder("validate")||e.preventDefault();const l=a(r).queryBuilder("getRules");a(r).next("#filter").val(JSON.stringify(l,null,2))}))}))}}}]);