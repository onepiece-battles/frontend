# Flutter web output is architecture-independent. Build it on the native
# BuildKit host platform so multi-arch builds do not run Dart under QEMU.
FROM --platform=$BUILDPLATFORM dart:3.9.2 AS build-env
#FROM registry.cn-hangzhou.aliyuncs.com/dart:3.3.4 AS build-env


ARG FLUTTER_VERSION=3.38.4
# Install Flutter
RUN git clone --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web
RUN flutter config --enable-web

# Copy files to the container and build your app
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --wasm --no-wasm-dry-run
RUN dart tool/version_web_assets.dart

# ===== Build the ngx_brotli dynamic modules =====
# Brotli is not bundled with the official nginx image. Compile just the two
# .so modules with --with-compat against the EXACT nginx version the runtime
# image pins below (1.27.4). If you bump either version, bump the other too —
# --with-compat modules only load into the same nginx version they were built
# against.
FROM alpine:3.20 AS nginx-brotli
ARG NGINX_VERSION=1.27.4
RUN apk add --no-cache build-base pcre-dev zlib-dev openssl-dev brotli-dev git wget \
    && git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli.git /usr/src/ngx_brotli \
    && wget -q https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O /usr/src/nginx.tar.gz \
    && tar -xzf /usr/src/nginx.tar.gz -C /usr/src \
    && cd /usr/src/nginx-${NGINX_VERSION} \
    && ./configure --with-compat --add-dynamic-module=/usr/src/ngx_brotli \
    && make modules \
    && strip objs/ngx_http_brotli_filter_module.so \
    && strip objs/ngx_http_brotli_static_module.so

# Use the Nginx image to serve the app. Pin the exact version the brotli
# modules were compiled against (see the nginx-brotli stage above).
FROM nginx:1.27.4-alpine

# Remove the default nginx.conf provided by the base image.
RUN rm /etc/nginx/conf.d/default.conf

# Load the brotli modules compiled in the previous stage.
COPY --from=nginx-brotli /usr/src/nginx-*/objs/ngx_http_brotli_*.so /usr/lib/nginx/modules/

# Copy the build from the previous stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

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
