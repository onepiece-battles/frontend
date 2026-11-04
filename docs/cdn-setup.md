# 前端服务与加速说明

## 现状:同源服务
Flutter web 重包(wasm/js/字体)**由 `onepiece-battles.com` 同源服务**:deploy.sh 本地构建
产物并打进 nginx 镜像(见 Dockerfile),nginx 在 ECS 上提供,带 gzip 压缩、哈希入口长缓存。
`/api`、`/chat`(WebSocket)由同一个 nginx 代理到后端。`<base href>` 保持 `/`。

## ⚠️ 不要做:独立 CDN 子域 + 跨域 base href
曾尝试把重包放到独立 CDN 子域(`cdn.onepiece-battles.com`,私有 OSS 回源),让 index.html 的
`<base href>` 指过去。**这与 Flutter Web 根本不兼容**:

- 文档在 `onepiece-battles.com`、base href 指向跨域的 `cdn.…`,Flutter 引擎/路由初始化时会对
  base URL 做源(origin)相关操作,抛 `JavaScriptError` → 首帧崩溃 → **灰屏**(manifest 的
  `start_url` 跨域被忽略是同一问题的旁证)。

所以 base href 必须与文档**同源**。独立子域 CDN 这条路对本应用走不通,已弃用(连带弃用了 OSS
`onepiece-assets` 桶、CDN 私有回源、wasm 预压那一整套)。

## 真正的加速选项(二选一)
首屏慢的根因经实测是 **ECS 出口带宽受限**(~3Mbps,2MB 的包要传约 6 秒),资源压缩本身没问题。

1. **升 ECS 公网带宽 / 改按量付费**(最省事、零风险):
   ECS 控制台 → 实例 → 配置变更 → 带宽升降级。10Mbps 约快 3 倍;按量付费峰值可到 100Mbps、
   按流量计费(记得设峰值上限 + 费用预警)。首屏包带内容哈希长缓存,用户首次加载后不再重下。

2. **CDN 挡在整个 `onepiece-battles.com` 域名前做同源加速**(规模化方案,较重):
   - 把 `onepiece-battles.com` 本身加成 CDN/DCDN 加速域名,**源站指 ECS**(IP 或只回源用的子域),
     回源 HOST = `onepiece-battles.com`、HTTPS 回源到 443;
   - 缓存规则:哈希资源长缓存,index.html / version.json / flutter_service_worker.js 不缓存,
     `/api/`、`/chat` 不缓存;
   - **开启 WebSocket**(保 `/chat`);上传 HTTPS 证书;
   - 最后才把 DNS 从直指 ECS 切到 CDN(可一键回滚:改回直指 ECS IP)。
   - 这样 base href 保持 `/`、同源、不碰 Flutter 跨域雷,静态资源在边缘缓存加速。
   - 注意:**用户上传的图片不走此 CDN**——它们由前端拿后端预签名 URL 后直连
     `onepiece-battles.oss-cn-shanghai.aliyuncs.com` 下载(另一个域名);给图片加速需在图片桶前
     单独挂 CDN,且预签名 + 私有桶让 CDN 缓存较难,是独立课题。
