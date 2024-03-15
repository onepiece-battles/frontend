FROM dart:stable AS build

# Install Flutter.
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set the Flutter SDK path.
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Check Flutter version.
RUN flutter doctor

# Enable Flutter web support.
RUN flutter config --enable-web

# Copy your app files into the container.
WORKDIR /app
COPY . .

# Get Flutter dependencies.
RUN flutter pub get

# Build your app for the web.
RUN flutter build web

# Use Nginx to serve your app.
FROM nginx:alpine

# Copy the Flutter web build files to the Nginx's html directory.
COPY --from=build /app/build/web/ /usr/share/nginx/html

# Expose HTTP.
EXPOSE 80

# Start Nginx.
CMD ["nginx", "-g", "daemon off;"]
