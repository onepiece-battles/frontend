#!/usr/bin/env bash
# 构建 Flutter web 并打进 nginx 镜像,全部由 onepiece-battles.com 同源服务
# (nginx 在 ECS 上,带 gzip + 哈希入口长缓存)。
#
# 说明:不要再用独立 CDN 子域 + <base href> 指过去的方式——跨域 base href 会让
# Flutter Web 在引擎/路由初始化时抛异常、首屏灰屏。要加速,见 docs/cdn-setup.md
# (升 ECS 带宽,或让 CDN 挡在整个 onepiece-battles.com 域名前做同源加速)。
set -euo pipefail

./generate.sh

# 本地构建 + 内容版本化(入口文件名带内容哈希,供浏览器长缓存)。
flutter build web --wasm --no-wasm-dry-run --base-href=/
dart tool/version_web_assets.dart

# 推送 nginx 镜像(镜像直接 COPY 本地 build/web,见 Dockerfile;服务 index.html +
# 静态资源 + /api + /chat)。
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.cn-shanghai.aliyuncs.com/onepiece-battles/onepiece-frontend:latest \
  --push .
