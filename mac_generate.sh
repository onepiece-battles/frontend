#!/bin/bash
echo "building api"
echo "// $(date -u)" >> ~/Documents/frontend/lib/config/onepiece_api_config.dart
dart run build_runner build --delete-conflicting-outputs
sed -i '$d' ~/Documents/frontend/lib/config/onepiece_api_config.dart