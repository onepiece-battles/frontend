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
RUN flutter build web --no-wasm-dry-run
RUN dart tool/version_web_assets.dart

# Use the Nginx image to serve the app
FROM nginx:alpine

# Remove the default nginx.conf provided by the base image.
RUN rm /etc/nginx/conf.d/default.conf

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
