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
- 开启 **私有 Bucket 回源**：域名 → 回源配置 → 私有 OSS Bucket 回源 → 开启
  （这样 CDN 有权读私有桶，浏览器仍无法直连 OSS）。

## 3. DNS
- 加一条 CNAME：`cdn.onepiece-battles.com` → 控制台分配的 CDN CNAME（`*.w.kunlun*.com` 之类）。

## 4. HTTPS
- CDN → HTTPS 配置：为 `cdn.onepiece-battles.com` 传证书（或用阿里云托管证书），开启 HTTPS。
- 开启 **HTTP/2**。（强制 HTTPS 跳转可选。）

## 5. 压缩（关键 —— 补回绕过 nginx 丢掉的 brotli）
- 性能优化 → **智能压缩（Gzip）**：开启。
- **Brotli 压缩**：开启。对 `application/wasm`、`text/javascript`、`application/json`、字体生效。
- 没有这步，几 MB 的 wasm 会未压缩传输，首屏可能比原来还慢。

## 6. 缓存规则（TTL，从严到宽按优先级配）
| 匹配 | 策略 |
|---|---|
| 正则 `^/main\.[0-9a-f]{32}\.dart\.(js\|wasm\|mjs)$` | 1 年，下发 `Cache-Control: public, max-age=31536000, immutable` |
| 正则 `^/main\.dart\.js_[0-9]+\.[0-9a-f]{32}\.part\.js$` | 同上（immutable） |
| 正则 `^/flutter_bootstrap\.[0-9a-f]{32}\.[0-9a-f]{32}\.js$` | 同上（immutable） |
| `/version.json`、`/flutter_service_worker.js` | **不缓存**（TTL 0 / no-cache）—— 每次发布都变 |
| `canvaskit/`、`assets/`、字体、图标 | 7 天（文件名稳定；升级 Flutter 时手动刷新） |

> 入口文件名带内容哈希，所以 immutable 安全：内容变 → 文件名变 → 自然 bust。

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
