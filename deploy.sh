#!/usr/bin/env bash
# Deploy:
#   • 重包(wasm/js/字体)走 Aliyun CDN —— base href 指向 CDN 子域名，产物上传到
#     私有 OSS 桶 onepiece-assets，CDN 以该私有桶为源回源，并在边缘做 brotli/gzip
#     压缩与缓存（配置见 docs/cdn-setup.md）。
#   • nginx 镜像只服务 index.html + /api + /chat（部署在 ECS）。
set -euo pipefail

# --- 配置 ---
# BASE_HREF 必须是 CDN 根（对应 bucket 根），所以 OSS 也上传到桶根（不要 web/ 子目录）。
# 兜底：把 BASE_HREF 设成 / 重新构建即可回到“全部由 nginx 同源服务”。
BASE_HREF="${BASE_HREF:-https://cdn.onepiece-battles.com/}"
OSS_TARGET="${OSS_TARGET:-oss://onepiece-assets/}"

./generate.sh

# 1) 本地构建 + 内容版本化（入口文件名带内容哈希，供 CDN/浏览器长缓存）。
flutter build web --wasm --no-wasm-dry-run --base-href="${BASE_HREF}"
dart tool/version_web_assets.dart

# 2) 增量上传到 OSS 私有桶（CDN 回源）。--update 只传新增/变更，保留旧哈希文件，
#    让已缓存旧版本的客户端还能拉到它引用的分片。
echo "上传 build/web 到 ${OSS_TARGET}"
ossutil cp -r build/web/ "${OSS_TARGET}" --recursive --update

# 3) 修正关键 Content-Type（浏览器强约束，且 ossutil 的扩展名推断不一定覆盖）：
#    .wasm 必须是 application/wasm（WebAssembly 流式编译），.mjs 必须是 JS（模块脚本），
#    否则浏览器会拒绝加载。强制覆盖这两类文件以写入正确类型。
ossutil cp -r build/web/ "${OSS_TARGET}" --recursive --force --include "*.wasm" \
  --meta "Content-Type:application/wasm"
ossutil cp -r build/web/ "${OSS_TARGET}" --recursive --force --include "*.mjs" \
  --meta "Content-Type:text/javascript"

# 缓存 TTL / 压缩 / CORS 全部在 CDN 侧按路径规则配置（见 docs/cdn-setup.md）：
#   - 内容哈希入口 -> 1 年 immutable
#   - version.json / flutter_service_worker.js -> 不缓存
#   - 其余 -> 适中 TTL
# 发布后记得刷新 CDN 上 version.json 与 flutter_service_worker.js 的缓存。

# 4) 推送 nginx 镜像（服务 index.html + /api + /chat；index.html 的 base href 已指向 CDN）。
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg BASE_HREF="${BASE_HREF}" \
  -t registry.cn-shanghai.aliyuncs.com/onepiece-battles/onepiece-frontend:latest \
  --push .
