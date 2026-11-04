# nginx 镜像:只服务 index.html（+ /api、/chat,见 nginx.conf）。Flutter web 重包由
# deploy.sh 在本地构建好后 COPY 进来（不在镜像内重复构建），所以这里打进的 index.html
# 与 OSS 上的资源共享同一套内容哈希;重包本身由 CDN 提供并在 CDN 边缘压缩,镜像内的
# 同名资源只作同源兜底。nginx 自身只发几 KB 的 index.html,gzip 足够,不再需要 brotli
# （去掉 brotli 动态模块后,也不必在镜像里编译/加载它——之前它正是 ERR_EMPTY_RESPONSE 的根因）。

FROM nginx:1.27.4-alpine

# Remove the default nginx.conf provided by the base image.
RUN rm /etc/nginx/conf.d/default.conf

# Copy the locally-built web bundle (built by deploy.sh). index.html's <base href>
# already points at the CDN; the hashed assets here are the same-origin fallback.
COPY build/web /usr/share/nginx/html

# replace with new nginx config file
COPY nginx.conf /etc/nginx/nginx.conf

# TLS key and certificate MUST be mounted at runtime via a volume or secret.
# Do NOT bake them into the image. The certificate is single-domain for the
# apex host onepiece-battles.com. Example docker run invocation:
#   docker run -p 80:80 -p 443:443 \
#     -v /path/to/deploy/onepiece-battles.com.pem:/etc/nginx/ssl/onepiece-battles.com.pem \
#     -v /path/to/deploy/onepiece-battles.com.key:/etc/nginx/ssl/onepiece-battles.com.key \
#     your-image:tag

# Expose ports
EXPOSE 80
EXPOSE 443
