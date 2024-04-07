# Start from the Dart image to get both Dart and Flutter SDKs
FROM dart:stable AS build-env

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web
RUN flutter channel stable && flutter upgrade && flutter config --enable-web

# Copy files to the container and build your app
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web

# Use the Nginx image to serve the app
FROM nginx:alpine

# Remove the default nginx.conf provided by the base image.
RUN rm /etc/nginx/conf.d/default.conf

# Copy the build from the previous stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# replace with new nginx config file
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80
