(self.webpackChunklinkspace=self.webpackChunklinkspace||[]).push([[770],{89190:(e,t,r)=>{var n=r(98052);e.exports=function(e,t,r){for(var s in t)n(e,s,t[s],r);return e}},21574:(e,t,r)=>{"use strict";var n=r(19781),s=r(1702),a=r(46916),i=r(47293),o=r(81956),u=r(25181),h=r(55296),c=r(47908),f=r(68361),l=Object.assign,p=Object.defineProperty,g=s([].concat);e.exports=!l||i((function(){if(n&&1!==l({b:1},l(p({},"a",{enumerable:!0,get:function(){p(this,"b",{value:3,enumerable:!1})}}),{b:2})).b)return!0;var e={},t={},r=Symbol(),s="abcdefghijklmnopqrst";return e[r]=7,s.split("").forEach((function(e){t[e]=e})),7!=l({},e)[r]||o(l({},t)).join("")!=s}))?function(e,t){for(var r=c(e),s=arguments.length,i=1,l=u.f,p=h.f;s>i;)for(var v,d=f(arguments[i++]),m=l?g(o(d),l(d)):o(d),y=m.length,w=0;y>w;)v=m[w++],n&&!a(p,d,v)||(r[v]=d[v]);return r}:l},81150:e=>{e.exports=Object.is||function(e,t){return e===t?0!==e||1/e==1/t:e!=e&&t!=t}},33197:(e,t,r)=>{var n=r(1702),s=2147483647,a=/[^\0-\u007E]/,i=/[.\u3002\uFF0E\uFF61]/g,o="Overflow: input needs wider integers to process",u=RangeError,h=n(i.exec),c=Math.floor,f=String.fromCharCode,l=n("".charCodeAt),p=n([].join),g=n([].push),v=n("".replace),d=n("".split),m=n("".toLowerCase),y=function(e){return e+22+75*(e<26)},w=function(e,t,r){var n=0;for(e=r?c(e/700):e>>1,e+=c(e/t);e>455;)e=c(e/35),n+=36;return c(n+36*e/(e+38))},b=function(e){var t=[];e=function(e){for(var t=[],r=0,n=e.length;r<n;){var s=l(e,r++);if(s>=55296&&s<=56319&&r<n){var a=l(e,r++);56320==(64512&a)?g(t,((1023&s)<<10)+(1023&a)+65536):(g(t,s),r--)}else g(t,s)}return t}(e);var r,n,a=e.length,i=128,h=0,v=72;for(r=0;r<e.length;r++)(n=e[r])<128&&g(t,f(n));var d=t.length,m=d;for(d&&g(t,"-");m<a;){var b=s;for(r=0;r<e.length;r++)(n=e[r])>=i&&n<b&&(b=n);var P=m+1;if(b-i>c((s-h)/P))throw u(o);for(h+=(b-i)*P,i=b,r=0;r<e.length;r++){if((n=e[r])<i&&++h>s)throw u(o);if(n==i){for(var U=h,k=36;;){var S=k<=v?1:k>=v+26?26:k-v;if(U<S)break;var R=U-S,L=36-S;g(t,f(y(S+R%L))),U=c(R/L),k+=36}g(t,f(y(U))),v=w(h,P,m==d),h=0,m++}}h++,i++}return p(t,"")};e.exports=function(e){var t,r,n=[],s=d(v(m(e),i,"."),".");for(t=0;t<s.length;t++)r=s[t],g(n,h(a,r)?"xn--"+b(r):r);return p(n,".")}},76091:(e,t,r)=>{var n=r(76530).PROPER,s=r(47293),a=r(81361);e.exports=function(e){return s((function(){return!!a[e]()||"​᠎"!=="​᠎"[e]()||n&&a[e].name!==e}))}},85143:(e,t,r)=>{var n=r(47293),s=r(5112),a=r(31913),i=s("iterator");e.exports=!n((function(){var e=new URL("b?a=1&b=2&c=3","http://a"),t=e.searchParams,r="";return e.pathname="c%20d",t.forEach((function(e,n){t.delete("b"),r+=n+e})),a&&!e.toJSON||!t.sort||"http://a/c%20d?a=1&c=3"!==e.href||"3"!==t.get("c")||"a=1"!==String(new URLSearchParams("?a=1"))||!t[i]||"a"!==new URL("https://a@b").username||"b"!==new URLSearchParams(new URLSearchParams("a=b")).get("a")||"xn--e1aybc"!==new URL("http://тест").host||"#%D0%B1"!==new URL("http://a#б").hash||"a1c3"!==r||"x"!==new URL("http://x",void 0).host}))},27852:(e,t,r)=>{"use strict";var n,s=r(82109),a=r(21470),i=r(31236).f,o=r(17466),u=r(41340),h=r(3929),c=r(84488),f=r(84964),l=r(31913),p=a("".endsWith),g=a("".slice),v=Math.min,d=f("endsWith");s({target:"String",proto:!0,forced:!!(l||d||(n=i(String.prototype,"endsWith"),!n||n.writable))&&!d},{endsWith:function(e){var t=u(c(this));h(e);var r=arguments.length>1?arguments[1]:void 0,n=t.length,s=void 0===r?n:v(o(r),n),a=u(e);return p?p(t,a,s):g(t,s-a.length,s)===a}})},4723:(e,t,r)=>{"use strict";var n=r(46916),s=r(27007),a=r(19670),i=r(68554),o=r(17466),u=r(41340),h=r(84488),c=r(58173),f=r(31530),l=r(97651);s("match",(function(e,t,r){return[function(t){var r=h(this),s=i(t)?void 0:c(t,e);return s?n(s,t,r):new RegExp(t)[e](u(r))},function(e){var n=a(this),s=u(e),i=r(t,n,s);if(i.done)return i.value;if(!n.global)return l(n,s);var h=n.unicode;n.lastIndex=0;for(var c,p=[],g=0;null!==(c=l(n,s));){var v=u(c[0]);p[g]=v,""===v&&(n.lastIndex=f(s,o(n.lastIndex),h)),g++}return 0===g?null:p}]}))},64765:(e,t,r)=>{"use strict";var n=r(46916),s=r(27007),a=r(19670),i=r(68554),o=r(84488),u=r(81150),h=r(41340),c=r(58173),f=r(97651);s("search",(function(e,t,r){return[function(t){var r=o(this),s=i(t)?void 0:c(t,e);return s?n(s,t,r):new RegExp(t)[e](h(r))},function(e){var n=a(this),s=h(e),i=r(t,n,s);if(i.done)return i.value;var o=n.lastIndex;u(o,0)||(n.lastIndex=0);var c=f(n,s);return u(n.lastIndex,o)||(n.lastIndex=o),null===c?-1:c.index}]}))},23157:(e,t,r)=>{"use strict";var n,s=r(82109),a=r(21470),i=r(31236).f,o=r(17466),u=r(41340),h=r(3929),c=r(84488),f=r(84964),l=r(31913),p=a("".startsWith),g=a("".slice),v=Math.min,d=f("startsWith");s({target:"String",proto:!0,forced:!!(l||d||(n=i(String.prototype,"startsWith"),!n||n.writable))&&!d},{startsWith:function(e){var t=u(c(this));h(e);var r=o(v(arguments.length>1?arguments[1]:void 0,t.length)),n=u(e);return p?p(t,n,r):g(t,r,r+n.length)===n}})},73210:(e,t,r)=>{"use strict";var n=r(82109),s=r(53111).trim;n({target:"String",proto:!0,forced:r(76091)("trim")},{trim:function(){return s(this)}})},65556:(e,t,r)=>{"use strict";r(66992);var n=r(82109),s=r(17854),a=r(46916),i=r(1702),o=r(19781),u=r(85143),h=r(98052),c=r(89190),f=r(58003),l=r(63061),p=r(29909),g=r(25787),v=r(60614),d=r(92597),m=r(49974),y=r(70648),w=r(19670),b=r(70111),P=r(41340),U=r(70030),k=r(79114),S=r(18554),R=r(71246),L=r(48053),x=r(5112),q=r(94362),H=x("iterator"),B="URLSearchParams",O=B+"Iterator",A=p.set,I=p.getterFor(B),j=p.getterFor(O),C=Object.getOwnPropertyDescriptor,E=function(e){if(!o)return s[e];var t=C(s,e);return t&&t.value},z=E("fetch"),F=E("Request"),W=E("Headers"),M=F&&F.prototype,$=W&&W.prototype,Q=s.RegExp,T=s.TypeError,D=s.decodeURIComponent,G=s.encodeURIComponent,J=i("".charAt),N=i([].join),K=i([].push),V=i("".replace),X=i([].shift),Y=i([].splice),Z=i("".split),_=i("".slice),ee=/\+/g,te=Array(4),re=function(e){return te[e-1]||(te[e-1]=Q("((?:%[\\da-f]{2}){"+e+"})","gi"))},ne=function(e){try{return D(e)}catch(t){return e}},se=function(e){var t=V(e,ee," "),r=4;try{return D(t)}catch(e){for(;r;)t=V(t,re(r--),ne);return t}},ae=/[!'()~]|%20/g,ie={"!":"%21","'":"%27","(":"%28",")":"%29","~":"%7E","%20":"+"},oe=function(e){return ie[e]},ue=function(e){return V(G(e),ae,oe)},he=l((function(e,t){A(this,{type:O,iterator:S(I(e).entries),kind:t})}),"Iterator",(function(){var e=j(this),t=e.kind,r=e.iterator.next(),n=r.value;return r.done||(r.value="keys"===t?n.key:"values"===t?n.value:[n.key,n.value]),r}),!0),ce=function(e){this.entries=[],this.url=null,void 0!==e&&(b(e)?this.parseObject(e):this.parseQuery("string"==typeof e?"?"===J(e,0)?_(e,1):e:P(e)))};ce.prototype={type:B,bindURL:function(e){this.url=e,this.update()},parseObject:function(e){var t,r,n,s,i,o,u,h=R(e);if(h)for(r=(t=S(e,h)).next;!(n=a(r,t)).done;){if(i=(s=S(w(n.value))).next,(o=a(i,s)).done||(u=a(i,s)).done||!a(i,s).done)throw T("Expected sequence with length 2");K(this.entries,{key:P(o.value),value:P(u.value)})}else for(var c in e)d(e,c)&&K(this.entries,{key:c,value:P(e[c])})},parseQuery:function(e){if(e)for(var t,r,n=Z(e,"&"),s=0;s<n.length;)(t=n[s++]).length&&(r=Z(t,"="),K(this.entries,{key:se(X(r)),value:se(N(r,"="))}))},serialize:function(){for(var e,t=this.entries,r=[],n=0;n<t.length;)e=t[n++],K(r,ue(e.key)+"="+ue(e.value));return N(r,"&")},update:function(){this.entries.length=0,this.parseQuery(this.url.query)},updateURL:function(){this.url&&this.url.update()}};var fe=function(){g(this,le),A(this,new ce(arguments.length>0?arguments[0]:void 0))},le=fe.prototype;if(c(le,{append:function(e,t){L(arguments.length,2);var r=I(this);K(r.entries,{key:P(e),value:P(t)}),r.updateURL()},delete:function(e){L(arguments.length,1);for(var t=I(this),r=t.entries,n=P(e),s=0;s<r.length;)r[s].key===n?Y(r,s,1):s++;t.updateURL()},get:function(e){L(arguments.length,1);for(var t=I(this).entries,r=P(e),n=0;n<t.length;n++)if(t[n].key===r)return t[n].value;return null},getAll:function(e){L(arguments.length,1);for(var t=I(this).entries,r=P(e),n=[],s=0;s<t.length;s++)t[s].key===r&&K(n,t[s].value);return n},has:function(e){L(arguments.length,1);for(var t=I(this).entries,r=P(e),n=0;n<t.length;)if(t[n++].key===r)return!0;return!1},set:function(e,t){L(arguments.length,1);for(var r,n=I(this),s=n.entries,a=!1,i=P(e),o=P(t),u=0;u<s.length;u++)(r=s[u]).key===i&&(a?Y(s,u--,1):(a=!0,r.value=o));a||K(s,{key:i,value:o}),n.updateURL()},sort:function(){var e=I(this);q(e.entries,(function(e,t){return e.key>t.key?1:-1})),e.updateURL()},forEach:function(e){for(var t,r=I(this).entries,n=m(e,arguments.length>1?arguments[1]:void 0),s=0;s<r.length;)n((t=r[s++]).value,t.key,this)},keys:function(){return new he(this,"keys")},values:function(){return new he(this,"values")},entries:function(){return new he(this,"entries")}},{enumerable:!0}),h(le,H,le.entries,{name:"entries"}),h(le,"toString",(function(){return I(this).serialize()}),{enumerable:!0}),f(fe,B),n({global:!0,constructor:!0,forced:!u},{URLSearchParams:fe}),!u&&v(W)){var pe=i($.has),ge=i($.set),ve=function(e){if(b(e)){var t,r=e.body;if(y(r)===B)return t=e.headers?new W(e.headers):new W,pe(t,"content-type")||ge(t,"content-type","application/x-www-form-urlencoded;charset=UTF-8"),U(e,{body:k(0,P(r)),headers:k(0,t)})}return e};if(v(z)&&n({global:!0,enumerable:!0,dontCallGetSet:!0,forced:!0},{fetch:function(e){return z(e,arguments.length>1?ve(arguments[1]):{})}}),v(F)){var de=function(e){return g(this,M),new F(e,arguments.length>1?ve(arguments[1]):{})};M.constructor=de,de.prototype=M,n({global:!0,constructor:!0,dontCallGetSet:!0,forced:!0},{Request:de})}}e.exports={URLSearchParams:fe,getState:I}},41637:(e,t,r)=>{r(65556)},68789:(e,t,r)=>{"use strict";r(78783);var n,s=r(82109),a=r(19781),i=r(85143),o=r(17854),u=r(49974),h=r(1702),c=r(98052),f=r(47045),l=r(25787),p=r(92597),g=r(21574),v=r(48457),d=r(41589),m=r(28710).codeAt,y=r(33197),w=r(41340),b=r(58003),P=r(48053),U=r(65556),k=r(29909),S=k.set,R=k.getterFor("URL"),L=U.URLSearchParams,x=U.getState,q=o.URL,H=o.TypeError,B=o.parseInt,O=Math.floor,A=Math.pow,I=h("".charAt),j=h(/./.exec),C=h([].join),E=h(1..toString),z=h([].pop),F=h([].push),W=h("".replace),M=h([].shift),$=h("".split),Q=h("".slice),T=h("".toLowerCase),D=h([].unshift),G="Invalid scheme",J="Invalid host",N="Invalid port",K=/[a-z]/i,V=/[\d+-.a-z]/i,X=/\d/,Y=/^0x/i,Z=/^[0-7]+$/,_=/^\d+$/,ee=/^[\da-f]+$/i,te=/[\0\t\n\r #%/:<>?@[\\\]^|]/,re=/[\0\t\n\r #/:<>?@[\\\]^|]/,ne=/^[\u0000-\u0020]+|[\u0000-\u0020]+$/g,se=/[\t\n\r]/g,ae=function(e){var t,r,n,s;if("number"==typeof e){for(t=[],r=0;r<4;r++)D(t,e%256),e=O(e/256);return C(t,".")}if("object"==typeof e){for(t="",n=function(e){for(var t=null,r=1,n=null,s=0,a=0;a<8;a++)0!==e[a]?(s>r&&(t=n,r=s),n=null,s=0):(null===n&&(n=a),++s);return s>r&&(t=n,r=s),t}(e),r=0;r<8;r++)s&&0===e[r]||(s&&(s=!1),n===r?(t+=r?":":"::",s=!0):(t+=E(e[r],16),r<7&&(t+=":")));return"["+t+"]"}return e},ie={},oe=g({},ie,{" ":1,'"':1,"<":1,">":1,"`":1}),ue=g({},oe,{"#":1,"?":1,"{":1,"}":1}),he=g({},ue,{"/":1,":":1,";":1,"=":1,"@":1,"[":1,"\\":1,"]":1,"^":1,"|":1}),ce=function(e,t){var r=m(e,0);return r>32&&r<127&&!p(t,e)?e:encodeURIComponent(e)},fe={ftp:21,file:null,http:80,https:443,ws:80,wss:443},le=function(e,t){var r;return 2==e.length&&j(K,I(e,0))&&(":"==(r=I(e,1))||!t&&"|"==r)},pe=function(e){var t;return e.length>1&&le(Q(e,0,2))&&(2==e.length||"/"===(t=I(e,2))||"\\"===t||"?"===t||"#"===t)},ge=function(e){return"."===e||"%2e"===T(e)},ve={},de={},me={},ye={},we={},be={},Pe={},Ue={},ke={},Se={},Re={},Le={},xe={},qe={},He={},Be={},Oe={},Ae={},Ie={},je={},Ce={},Ee=function(e,t,r){var n,s,a,i=w(e);if(t){if(s=this.parse(i))throw H(s);this.searchParams=null}else{if(void 0!==r&&(n=new Ee(r,!0)),s=this.parse(i,null,n))throw H(s);(a=x(new L)).bindURL(this),this.searchParams=a}};Ee.prototype={type:"URL",parse:function(e,t,r){var s,a,i,o,u,h=this,c=t||ve,f=0,l="",g=!1,m=!1,y=!1;for(e=w(e),t||(h.scheme="",h.username="",h.password="",h.host=null,h.port=null,h.path=[],h.query=null,h.fragment=null,h.cannotBeABaseURL=!1,e=W(e,ne,"")),e=W(e,se,""),s=v(e);f<=s.length;){switch(a=s[f],c){case ve:if(!a||!j(K,a)){if(t)return G;c=me;continue}l+=T(a),c=de;break;case de:if(a&&(j(V,a)||"+"==a||"-"==a||"."==a))l+=T(a);else{if(":"!=a){if(t)return G;l="",c=me,f=0;continue}if(t&&(h.isSpecial()!=p(fe,l)||"file"==l&&(h.includesCredentials()||null!==h.port)||"file"==h.scheme&&!h.host))return;if(h.scheme=l,t)return void(h.isSpecial()&&fe[h.scheme]==h.port&&(h.port=null));l="","file"==h.scheme?c=qe:h.isSpecial()&&r&&r.scheme==h.scheme?c=ye:h.isSpecial()?c=Ue:"/"==s[f+1]?(c=we,f++):(h.cannotBeABaseURL=!0,F(h.path,""),c=Ie)}break;case me:if(!r||r.cannotBeABaseURL&&"#"!=a)return G;if(r.cannotBeABaseURL&&"#"==a){h.scheme=r.scheme,h.path=d(r.path),h.query=r.query,h.fragment="",h.cannotBeABaseURL=!0,c=Ce;break}c="file"==r.scheme?qe:be;continue;case ye:if("/"!=a||"/"!=s[f+1]){c=be;continue}c=ke,f++;break;case we:if("/"==a){c=Se;break}c=Ae;continue;case be:if(h.scheme=r.scheme,a==n)h.username=r.username,h.password=r.password,h.host=r.host,h.port=r.port,h.path=d(r.path),h.query=r.query;else if("/"==a||"\\"==a&&h.isSpecial())c=Pe;else if("?"==a)h.username=r.username,h.password=r.password,h.host=r.host,h.port=r.port,h.path=d(r.path),h.query="",c=je;else{if("#"!=a){h.username=r.username,h.password=r.password,h.host=r.host,h.port=r.port,h.path=d(r.path),h.path.length--,c=Ae;continue}h.username=r.username,h.password=r.password,h.host=r.host,h.port=r.port,h.path=d(r.path),h.query=r.query,h.fragment="",c=Ce}break;case Pe:if(!h.isSpecial()||"/"!=a&&"\\"!=a){if("/"!=a){h.username=r.username,h.password=r.password,h.host=r.host,h.port=r.port,c=Ae;continue}c=Se}else c=ke;break;case Ue:if(c=ke,"/"!=a||"/"!=I(l,f+1))continue;f++;break;case ke:if("/"!=a&&"\\"!=a){c=Se;continue}break;case Se:if("@"==a){g&&(l="%40"+l),g=!0,i=v(l);for(var b=0;b<i.length;b++){var P=i[b];if(":"!=P||y){var U=ce(P,he);y?h.password+=U:h.username+=U}else y=!0}l=""}else if(a==n||"/"==a||"?"==a||"#"==a||"\\"==a&&h.isSpecial()){if(g&&""==l)return"Invalid authority";f-=v(l).length+1,l="",c=Re}else l+=a;break;case Re:case Le:if(t&&"file"==h.scheme){c=Be;continue}if(":"!=a||m){if(a==n||"/"==a||"?"==a||"#"==a||"\\"==a&&h.isSpecial()){if(h.isSpecial()&&""==l)return J;if(t&&""==l&&(h.includesCredentials()||null!==h.port))return;if(o=h.parseHost(l))return o;if(l="",c=Oe,t)return;continue}"["==a?m=!0:"]"==a&&(m=!1),l+=a}else{if(""==l)return J;if(o=h.parseHost(l))return o;if(l="",c=xe,t==Le)return}break;case xe:if(!j(X,a)){if(a==n||"/"==a||"?"==a||"#"==a||"\\"==a&&h.isSpecial()||t){if(""!=l){var k=B(l,10);if(k>65535)return N;h.port=h.isSpecial()&&k===fe[h.scheme]?null:k,l=""}if(t)return;c=Oe;continue}return N}l+=a;break;case qe:if(h.scheme="file","/"==a||"\\"==a)c=He;else{if(!r||"file"!=r.scheme){c=Ae;continue}if(a==n)h.host=r.host,h.path=d(r.path),h.query=r.query;else if("?"==a)h.host=r.host,h.path=d(r.path),h.query="",c=je;else{if("#"!=a){pe(C(d(s,f),""))||(h.host=r.host,h.path=d(r.path),h.shortenPath()),c=Ae;continue}h.host=r.host,h.path=d(r.path),h.query=r.query,h.fragment="",c=Ce}}break;case He:if("/"==a||"\\"==a){c=Be;break}r&&"file"==r.scheme&&!pe(C(d(s,f),""))&&(le(r.path[0],!0)?F(h.path,r.path[0]):h.host=r.host),c=Ae;continue;case Be:if(a==n||"/"==a||"\\"==a||"?"==a||"#"==a){if(!t&&le(l))c=Ae;else if(""==l){if(h.host="",t)return;c=Oe}else{if(o=h.parseHost(l))return o;if("localhost"==h.host&&(h.host=""),t)return;l="",c=Oe}continue}l+=a;break;case Oe:if(h.isSpecial()){if(c=Ae,"/"!=a&&"\\"!=a)continue}else if(t||"?"!=a)if(t||"#"!=a){if(a!=n&&(c=Ae,"/"!=a))continue}else h.fragment="",c=Ce;else h.query="",c=je;break;case Ae:if(a==n||"/"==a||"\\"==a&&h.isSpecial()||!t&&("?"==a||"#"==a)){if(".."===(u=T(u=l))||"%2e."===u||".%2e"===u||"%2e%2e"===u?(h.shortenPath(),"/"==a||"\\"==a&&h.isSpecial()||F(h.path,"")):ge(l)?"/"==a||"\\"==a&&h.isSpecial()||F(h.path,""):("file"==h.scheme&&!h.path.length&&le(l)&&(h.host&&(h.host=""),l=I(l,0)+":"),F(h.path,l)),l="","file"==h.scheme&&(a==n||"?"==a||"#"==a))for(;h.path.length>1&&""===h.path[0];)M(h.path);"?"==a?(h.query="",c=je):"#"==a&&(h.fragment="",c=Ce)}else l+=ce(a,ue);break;case Ie:"?"==a?(h.query="",c=je):"#"==a?(h.fragment="",c=Ce):a!=n&&(h.path[0]+=ce(a,ie));break;case je:t||"#"!=a?a!=n&&("'"==a&&h.isSpecial()?h.query+="%27":h.query+="#"==a?"%23":ce(a,ie)):(h.fragment="",c=Ce);break;case Ce:a!=n&&(h.fragment+=ce(a,oe))}f++}},parseHost:function(e){var t,r,n;if("["==I(e,0)){if("]"!=I(e,e.length-1))return J;if(t=function(e){var t,r,n,s,a,i,o,u=[0,0,0,0,0,0,0,0],h=0,c=null,f=0,l=function(){return I(e,f)};if(":"==l()){if(":"!=I(e,1))return;f+=2,c=++h}for(;l();){if(8==h)return;if(":"!=l()){for(t=r=0;r<4&&j(ee,l());)t=16*t+B(l(),16),f++,r++;if("."==l()){if(0==r)return;if(f-=r,h>6)return;for(n=0;l();){if(s=null,n>0){if(!("."==l()&&n<4))return;f++}if(!j(X,l()))return;for(;j(X,l());){if(a=B(l(),10),null===s)s=a;else{if(0==s)return;s=10*s+a}if(s>255)return;f++}u[h]=256*u[h]+s,2!=++n&&4!=n||h++}if(4!=n)return;break}if(":"==l()){if(f++,!l())return}else if(l())return;u[h++]=t}else{if(null!==c)return;f++,c=++h}}if(null!==c)for(i=h-c,h=7;0!=h&&i>0;)o=u[h],u[h--]=u[c+i-1],u[c+--i]=o;else if(8!=h)return;return u}(Q(e,1,-1)),!t)return J;this.host=t}else if(this.isSpecial()){if(e=y(e),j(te,e))return J;if(t=function(e){var t,r,n,s,a,i,o,u=$(e,".");if(u.length&&""==u[u.length-1]&&u.length--,(t=u.length)>4)return e;for(r=[],n=0;n<t;n++){if(""==(s=u[n]))return e;if(a=10,s.length>1&&"0"==I(s,0)&&(a=j(Y,s)?16:8,s=Q(s,8==a?1:2)),""===s)i=0;else{if(!j(10==a?_:8==a?Z:ee,s))return e;i=B(s,a)}F(r,i)}for(n=0;n<t;n++)if(i=r[n],n==t-1){if(i>=A(256,5-t))return null}else if(i>255)return null;for(o=z(r),n=0;n<r.length;n++)o+=r[n]*A(256,3-n);return o}(e),null===t)return J;this.host=t}else{if(j(re,e))return J;for(t="",r=v(e),n=0;n<r.length;n++)t+=ce(r[n],ie);this.host=t}},cannotHaveUsernamePasswordPort:function(){return!this.host||this.cannotBeABaseURL||"file"==this.scheme},includesCredentials:function(){return""!=this.username||""!=this.password},isSpecial:function(){return p(fe,this.scheme)},shortenPath:function(){var e=this.path,t=e.length;!t||"file"==this.scheme&&1==t&&le(e[0],!0)||e.length--},serialize:function(){var e=this,t=e.scheme,r=e.username,n=e.password,s=e.host,a=e.port,i=e.path,o=e.query,u=e.fragment,h=t+":";return null!==s?(h+="//",e.includesCredentials()&&(h+=r+(n?":"+n:"")+"@"),h+=ae(s),null!==a&&(h+=":"+a)):"file"==t&&(h+="//"),h+=e.cannotBeABaseURL?i[0]:i.length?"/"+C(i,"/"):"",null!==o&&(h+="?"+o),null!==u&&(h+="#"+u),h},setHref:function(e){var t=this.parse(e);if(t)throw H(t);this.searchParams.update()},getOrigin:function(){var e=this.scheme,t=this.port;if("blob"==e)try{return new ze(e.path[0]).origin}catch(e){return"null"}return"file"!=e&&this.isSpecial()?e+"://"+ae(this.host)+(null!==t?":"+t:""):"null"},getProtocol:function(){return this.scheme+":"},setProtocol:function(e){this.parse(w(e)+":",ve)},getUsername:function(){return this.username},setUsername:function(e){var t=v(w(e));if(!this.cannotHaveUsernamePasswordPort()){this.username="";for(var r=0;r<t.length;r++)this.username+=ce(t[r],he)}},getPassword:function(){return this.password},setPassword:function(e){var t=v(w(e));if(!this.cannotHaveUsernamePasswordPort()){this.password="";for(var r=0;r<t.length;r++)this.password+=ce(t[r],he)}},getHost:function(){var e=this.host,t=this.port;return null===e?"":null===t?ae(e):ae(e)+":"+t},setHost:function(e){this.cannotBeABaseURL||this.parse(e,Re)},getHostname:function(){var e=this.host;return null===e?"":ae(e)},setHostname:function(e){this.cannotBeABaseURL||this.parse(e,Le)},getPort:function(){var e=this.port;return null===e?"":w(e)},setPort:function(e){this.cannotHaveUsernamePasswordPort()||(""==(e=w(e))?this.port=null:this.parse(e,xe))},getPathname:function(){var e=this.path;return this.cannotBeABaseURL?e[0]:e.length?"/"+C(e,"/"):""},setPathname:function(e){this.cannotBeABaseURL||(this.path=[],this.parse(e,Oe))},getSearch:function(){var e=this.query;return e?"?"+e:""},setSearch:function(e){""==(e=w(e))?this.query=null:("?"==I(e,0)&&(e=Q(e,1)),this.query="",this.parse(e,je)),this.searchParams.update()},getSearchParams:function(){return this.searchParams.facade},getHash:function(){var e=this.fragment;return e?"#"+e:""},setHash:function(e){""!=(e=w(e))?("#"==I(e,0)&&(e=Q(e,1)),this.fragment="",this.parse(e,Ce)):this.fragment=null},update:function(){this.query=this.searchParams.serialize()||null}};var ze=function(e){var t=l(this,Fe),r=P(arguments.length,1)>1?arguments[1]:void 0,n=S(t,new Ee(e,!1,r));a||(t.href=n.serialize(),t.origin=n.getOrigin(),t.protocol=n.getProtocol(),t.username=n.getUsername(),t.password=n.getPassword(),t.host=n.getHost(),t.hostname=n.getHostname(),t.port=n.getPort(),t.pathname=n.getPathname(),t.search=n.getSearch(),t.searchParams=n.getSearchParams(),t.hash=n.getHash())},Fe=ze.prototype,We=function(e,t){return{get:function(){return R(this)[e]()},set:t&&function(e){return R(this)[t](e)},configurable:!0,enumerable:!0}};if(a&&(f(Fe,"href",We("serialize","setHref")),f(Fe,"origin",We("getOrigin")),f(Fe,"protocol",We("getProtocol","setProtocol")),f(Fe,"username",We("getUsername","setUsername")),f(Fe,"password",We("getPassword","setPassword")),f(Fe,"host",We("getHost","setHost")),f(Fe,"hostname",We("getHostname","setHostname")),f(Fe,"port",We("getPort","setPort")),f(Fe,"pathname",We("getPathname","setPathname")),f(Fe,"search",We("getSearch","setSearch")),f(Fe,"searchParams",We("getSearchParams")),f(Fe,"hash",We("getHash","setHash"))),c(Fe,"toJSON",(function(){return R(this).serialize()}),{enumerable:!0}),c(Fe,"toString",(function(){return R(this).serialize()}),{enumerable:!0}),q){var Me=q.createObjectURL,$e=q.revokeObjectURL;Me&&c(ze,"createObjectURL",u(Me,q)),$e&&c(ze,"revokeObjectURL",u($e,q))}b(ze,"URL"),s({global:!0,constructor:!0,forced:!i,sham:!a},{URL:ze})},60285:(e,t,r)=>{r(68789)}}]);