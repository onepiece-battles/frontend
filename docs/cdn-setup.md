# 静态重包走 CDN（私有 OSS 源）配置清单

目标：Flutter web 重包（wasm/js/字体）由 **Aliyun CDN** 服务，源站是**私有** OSS 桶
`onepiece-assets`；边缘做 brotli/gzip 压缩、按文件类型做长/短缓存；并为站点源配好 CORS。
`index.html` 仍由 ECS 上的 nginx 服务（`no-cache`），`/api`、`/chat` 仍走 nginx→backend。

架构：
```
浏览器 ──(index.html)──> nginx(ECS)            # 只发 index.html + /api + /chat
      ──(wasm/js/字体)─> cdn.onepiece-battles.com ──回源──> onepiece-assets(私有 OSS)
```

---

## 1. OSS 桶
- `onepiece-assets` 保持 **私有（Private ACL）**。浏览器不直连 OSS；只由 CDN 回源读取。
- 区域 `oss-cn-shanghai`（与 ECS/CDN 同区，回源最快）。
- 产物由 `deploy.sh` 上传到**桶根**（base href = CDN 根 = 桶根；不要用 `web/` 子目录）。

## 2. 添加 CDN 加速域名
- CDN 控制台 → 域名管理 → 添加域名：`cdn.onepiece-battles.com`
- 源站类型：**OSS 域名** → 选 `onepiece-assets.oss-cn-shanghai.aliyuncs.com`
  （必须是「OSS 域名」类型,私有回源的 STS 签名才会对这个桶生效）。
- 开启 **私有 Bucket 回源**：域名 → 回源配置 → 阿里云 OSS 私有 Bucket 回源 → 状态 → 开启。
  - **关键**:开启时会弹「云资源访问授权」,**必须点「同意授权」**(授予角色
    `AliyunCDNAccessingPrivateOSSRole`)。只拨开关、不完成这步,CDN 回源仍是匿名的,
    OSS 会一律 403:`AccessDenied — You have no right to access this object because of
    bucket acl`。授权后配置下发到各边缘节点约需几分钟。
  - 回源 HOST 保持为 OSS 桶域名(`onepiece-assets.oss-cn-shanghai.aliyuncs.com`),
    不要改成加速域名,否则 OSS 收到的 Host 不对、签名校验失败同样 403。
  - 桶**保持私有**;本账号若开了「阻止公共访问」,设公共读会被拒,也不需要设。
  - 坑:私有 Bucket 回源 与 OSS「静态网站托管」的默认首页功能冲突,**别在这个桶上开静态托管**。

## 3. DNS
- 加一条 CNAME：`cdn.onepiece-battles.com` → 控制台分配的 CDN CNAME（`*.w.kunlun*.com` 之类）。

## 4. HTTPS
- CDN → HTTPS 配置：为 `cdn.onepiece-battles.com` 传证书（或用阿里云托管证书），开启 HTTPS。
- 开启 **HTTP/2**。（强制 HTTPS 跳转可选。）

## 5. 压缩（关键 —— 补回绕过 nginx 丢掉的 brotli）
- 性能优化 → **智能压缩（Gzip）**：开启。
- **Brotli 压缩**：开启。对 `text/javascript`、`application/json`、字体等文本类型生效
  （与体积无关:实测 4MB 的 `main.<hash>.dart.js` 也会被压)。
- ⚠️ **`application/wasm` 不在 CDN 可压类型清单里,且清单改不了。** 而 wasm 是首屏最大的文件。
  因此 `deploy.sh` 对 `.wasm` **在上传前用 brotli 预压缩**,带 `Content-Encoding: br` 上传,
  CDN 透传、浏览器自动解压(约 6MB → ~2MB)。这一步在脚本里完成,CDN 侧无需配置。

## 6. 缓存规则（缓存配置 → 缓存过期时间）
控制台只有「目录 / 文件后缀名」两种类型(无正则),但「目录」支持完整路径,所以用目录+完整
路径精确命中单文件。按下面 3 条配(权重大=优先级高;各条都开「客户端跟随 CDN 缓存策略」,
让浏览器也按此 TTL 强缓存):

| 类型 | 地址 | 过期时间 | 权重 |
|---|---|---|---|
| 目录 | `/version.json` | 0 秒(不缓存) | 90 |
| 目录 | `/flutter_service_worker.js` | 0 秒(不缓存) | 90 |
| 目录 | `/` | 30 天 | 10 |

> 入口文件名带内容哈希,内容变→文件名变→新 URL 自然 miss 重新拉,所以 `/` 兜底 30 天安全;
> 唯二会「同名换内容」的 `version.json`、`flutter_service_worker.js` 用前两条强制 0 秒,靠权重
> 压过兜底规则。升级 Flutter 导致 `canvaskit/`、字体等稳定名文件内容变时,30 天内自愈,或发布后
> 手动刷新 CDN 缓存。

「自定义 CacheKey」保持默认即可(静态资源无查询参数,不需要定制缓存键)。

## 7. CORS（assets 与站点不同源）
- `index.html` 在 `onepiece-battles.com`，assets 在 `cdn.onepiece-battles.com` → 跨域。
- OSS 侧已配好 CORS（允许 `https://onepiece-battles.com` 的 GET/HEAD）。确保 CDN **回源透传**
  OSS 的 CORS 响应头；若不透传，在 CDN「HTTP 头配置」里手动下发：
  - `Access-Control-Allow-Origin: https://onepiece-battles.com`
  - `Access-Control-Allow-Methods: GET, HEAD`

## 8. 发布与验证
```bash
./deploy.sh                      # base href 已指向 CDN

# 验证（替换 <hash> 为实际构建出的文件名）
curl -I https://cdn.onepiece-battles.com/version.json
curl -I -H 'Accept-Encoding: br' \
  https://cdn.onepiece-battles.com/main.<hash>.dart.wasm
# 期望：200；Content-Type: application/wasm；Content-Encoding: br；
#       Cache-Control: public, max-age=31536000, immutable
```
浏览器打开站点 → Network：确认 assets 从 `cdn.*` 加载、无 CORS 报错、wasm 命中 br、
返回访问走 304/强缓存。发布后刷新 CDN 上 `version.json` 与 `flutter_service_worker.js`
（控制台「刷新预热」或 `aliyun cdn RefreshObjectCaches`）。

## 9. 回滚兜底
CDN 若出问题，用 `BASE_HREF=/ ./deploy.sh` 重新构建部署，即可回到“所有静态资源由 nginx
同源服务（含 brotli）”。Dockerfile 的 `ARG BASE_HREF` 默认就是 `/`。
