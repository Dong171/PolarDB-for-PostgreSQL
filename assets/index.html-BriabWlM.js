import{_ as r,r as s,o as p,c as i,a as n,b as a,d as e,w as o}from"./app-CqYFEabH.js";const u={},d=n("hr",null,null,-1),k=n("h3",{id:"通过-docker-快速使用",tabindex:"-1"},[n("a",{class:"header-anchor",href:"#通过-docker-快速使用"},[n("span",null,"通过 Docker 快速使用")])],-1),_={href:"https://hub.docker.com/r/polardb/polardb_pg_local_instance/tags",target:"_blank",rel:"noopener noreferrer"},m=n("div",{class:"language-bash","data-ext":"sh","data-title":"sh"},[n("pre",{class:"language-bash"},[n("code",null,[n("span",{class:"token comment"},"# 拉取镜像并运行容器"),a(`
`),n("span",{class:"token function"},"docker"),a(` pull polardb/polardb_pg_local_instance:15
`),n("span",{class:"token function"},"docker"),a(" run "),n("span",{class:"token parameter variable"},"-it"),a(),n("span",{class:"token parameter variable"},"--rm"),a(` polardb/polardb_pg_local_instance:15 psql
`),n("span",{class:"token comment"},"# 测试可用性"),a(`
`),n("span",{class:"token assign-left variable"},"postgres"),n("span",{class:"token operator"},"="),n("span",{class:"token comment"},"# SELECT version();"),a(`
                                   version
----------------------------------------------------------------------
 PostgreSQL `),n("span",{class:"token number"},"15"),a(".x "),n("span",{class:"token punctuation"},"("),a("PolarDB "),n("span",{class:"token number"},"15"),a(".x.x.x build xxxxxxxx"),n("span",{class:"token punctuation"},")"),a(" on "),n("span",{class:"token punctuation"},"{"),a("your_platform"),n("span",{class:"token punctuation"},"}"),a(`
`),n("span",{class:"token punctuation"},"("),n("span",{class:"token number"},"1"),a(" row"),n("span",{class:"token punctuation"},")"),a(`
`)])])],-1),h=n("div",{class:"language-bash","data-ext":"sh","data-title":"sh"},[n("pre",{class:"language-bash"},[n("code",null,[n("span",{class:"token comment"},"# 拉取镜像并运行容器"),a(`
`),n("span",{class:"token function"},"docker"),a(` pull registry.cn-hangzhou.aliyuncs.com/polardb_pg/polardb_pg_local_instance:15
`),n("span",{class:"token function"},"docker"),a(" run "),n("span",{class:"token parameter variable"},"-it"),a(),n("span",{class:"token parameter variable"},"--rm"),a(` registry.cn-hangzhou.aliyuncs.com/polardb_pg/polardb_pg_local_instance:15 psql
`),n("span",{class:"token comment"},"# 测试可用性"),a(`
`),n("span",{class:"token assign-left variable"},"postgres"),n("span",{class:"token operator"},"="),n("span",{class:"token comment"},"# SELECT version();"),a(`
                                   version
----------------------------------------------------------------------
 PostgreSQL `),n("span",{class:"token number"},"15"),a(".x "),n("span",{class:"token punctuation"},"("),a("PolarDB "),n("span",{class:"token number"},"15"),a(".x.x.x build xxxxxxxx"),n("span",{class:"token punctuation"},")"),a(" on "),n("span",{class:"token punctuation"},"{"),a("your_platform"),n("span",{class:"token punctuation"},"}"),a(`
`),n("span",{class:"token punctuation"},"("),n("span",{class:"token number"},"1"),a(" row"),n("span",{class:"token punctuation"},")"),a(`
`)])])],-1);function b(x,g){const l=s("ExternalLinkIcon"),t=s("CodeGroupItem"),c=s("CodeGroup");return p(),i("div",null,[d,k,n("p",null,[a("拉取 PolarDB for PostgreSQL 的 "),n("a",_,[a("单机实例镜像"),e(l)]),a("，运行容器并试用 PolarDB-PG：")]),e(c,null,{default:o(()=>[e(t,{title:"DockerHub"},{default:o(()=>[m]),_:1}),e(t,{title:"阿里云 ACR"},{default:o(()=>[h]),_:1})]),_:1})])}const v=r(u,[["render",b],["__file","index.html.vue"]]),C=JSON.parse('{"path":"/zh/","title":"文档","lang":"zh-CN","frontmatter":{"home":true,"title":"文档","heroImage":"/images/polardb.png","footer":"Apache 2.0 Licensed | Copyright © Alibaba Group, Inc."},"headers":[{"level":3,"title":"通过 Docker 快速使用","slug":"通过-docker-快速使用","link":"#通过-docker-快速使用","children":[]}],"git":{"updatedTime":1729232520000},"filePathRelative":"zh/README.md"}');export{v as comp,C as data};