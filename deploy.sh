#!/usr/bin/env bash
# Deploy:
#   • 重包(wasm/js/字体)走 Aliyun CDN —— 产物上传到私有 OSS 桶 onepiece-assets,
#     CDN 以该私有桶为源(私有 Bucket 回源 + STS 签名,见 docs/cdn-setup.md)回源,
#     边缘对 js/json/字体做 brotli/gzip 压缩并按路径缓存。
#   • application/wasm 不在 CDN 可压类型清单里,所以 .wasm 在本步用 brotli 预压缩,
#     带 Content-Encoding: br 上传(浏览器自动解压)。
#   • nginx 镜像只服务 index.html + /api + /chat(部署在 ECS);它用的正是本地这份
#     构建产物,所以 index.html 引用的哈希文件名与 OSS 上的资源永远一致。
set -euo pipefail

# --- 配置 ---
# BASE_HREF 是浏览器加载静态资源的根:指向 CDN 子域名时,index.html 的 <base href>
# 会被改写成它,重包就从 CDN 加载。兜底:设成 / 重新构建即回到“全部由 nginx 同源服务”。
# 注意:flutter 的 --base-href 只接受路径、不收完整 URL,所以统一用 / 构建后再改写
# index.html(资源文件与 base-href 无关,运行时按页面 <base href> 解析)。
BASE_HREF="${BASE_HREF:-https://cdn.onepiece-battles.com/}"
OSS_TARGET="${OSS_TARGET:-oss://onepiece-assets/}"

./generate.sh

# 1) 本地构建 + 内容版本化(入口文件名带内容哈希,供 CDN/浏览器长缓存)。
flutter build web --wasm --no-wasm-dry-run --base-href=/
dart tool/version_web_assets.dart

# 2) 把 index.html 的 <base href="/"> 改写成 BASE_HREF(BASE_HREF=/ 时为无操作)。
#    这份 index.html 会被打进 nginx 镜像,从而让浏览器去 CDN 取重包。
tmp_index="$(mktemp)"
sed "s|<base href=\"/\">|<base href=\"${BASE_HREF}\">|" build/web/index.html > "$tmp_index"
mv "$tmp_index" build/web/index.html

# 3) 上传到 OSS 私有桶(CDN 回源)。-f 覆盖同名、保留旧哈希文件(让已缓存旧版本的
#    客户端仍能拉到它引用的分片);不删除,故旧哈希会累积,属预期。
#    .wasm 在下一步单独预压上传,这里先排除。
echo "上传 build/web(除 .wasm 外)到 ${OSS_TARGET}"
ossutil cp build/web/ "${OSS_TARGET}" -r -f --exclude "*.wasm"

# 4) 修正 .mjs 的 Content-Type(浏览器按模块脚本加载,ossutil 的扩展名推断可能给成
#    application/octet-stream 导致被拒)。.mjs 仍由 CDN 边缘压缩。
ossutil cp build/web/ "${OSS_TARGET}" -r -f --include "*.mjs" \
  --meta "Content-Type:text/javascript"

# 5) .wasm 预压缩:Aliyun CDN 智能压缩不覆盖 application/wasm(与体积无关),而 wasm 是
#    首屏大头。这里用本机 brotli 压好,带 Content-Encoding: br + Content-Type 上传,
#    CDN 透传、浏览器自动解压。能跑 Flutter wasm 的浏览器都支持 br。
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
while IFS= read -r -d '' f; do
  rel="${f#build/web/}"
  mkdir -p "$work/$(dirname "$rel")"
  brotli -k -q 11 -f "$f" -o "$work/${rel}.br"
  echo "  预压 ${rel}: $(du -h "$f" | cut -f1) → $(du -h "$work/${rel}.br" | cut -f1)"
  ossutil cp "$work/${rel}.br" "${OSS_TARGET}${rel}" -f \
    --meta "Content-Type:application/wasm#Content-Encoding:br"
done < <(find build/web -name '*.wasm' -print0)

# 缓存 TTL / 其余类型的压缩 / CORS 全部在 CDN 侧按路径规则配置(见 docs/cdn-setup.md):
#   - 内容哈希入口 -> 30 天(文件名带哈希,改即换名,长缓存安全)
#   - version.json / flutter_service_worker.js -> 不缓存
# 发布后记得刷新 CDN 上 version.json 与 flutter_service_worker.js 的缓存。

# 6) 推送 nginx 镜像(服务 index.html + /api + /chat)。镜像直接 COPY 本地 build/web,
#    不在镜像内重复构建,保证 index.html 与 OSS 资源的哈希一致。
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.cn-shanghai.aliyuncs.com/onepiece-battles/onepiece-frontend:latest \
  --push .
