"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[387],{63311:(e,t,l)=>{l.r(t),l.d(t,{default:()=>s});l(25728),l(60228);var n=l(19755);function s(e){e.on("click",(function(e){var t=n(e.target);if(t.closest(".table-curval-group").length)if(confirm("Are you sure want to permanently remove this item?")){var l=t.closest(".table-curval-item"),s=l.parent();l.remove(),s&&1===s.children().length&&s.children(".odd").children(".dataTables_empty").show()}else e.preventDefault();else if(t.closest(".select-widget").length){var a=t.closest(".answer").find("input").prop("id"),i=t.closest(".select-widget").find(".current");i.find("li[data-list-item=".concat(a,"]")).remove(),t.closest(".answer").remove();var r=i.children("[data-list-item]:not([hidden])");i.toggleClass("empty",0===r.length)}}))}}}]);