"use strict";(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[764],{97246:(e,t,n)=>{n.r(t),n.d(t,{default:()=>o});var s=n(60023),r=n(17527),i=n(74692);class a extends r.uA{constructor(e){super(e),this.initMarkdownEditor()}renderMarkdown(e){const t=i("<span>").text(e).html();return(0,s.xI)(t)}initMarkdownEditor(){s.xI.use({breaks:!0});const e=i(this.element).find(".js-markdown-input"),t=i(this.element).find(".js-markdown-preview");i().on("ready",(()=>{if(""!==e.val()){const n=this.renderMarkdown(e.val());t.html(n)}})),e.keyup((()=>{const n=e.val();if(n&&""!==n){const e=this.renderMarkdown(n);t.html(e)}else t.html('<p class="text-info">Nothing to preview!</p>')}))}}const o=a}}]);