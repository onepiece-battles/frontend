#!/bin/bash
echo "building api"
echo "// $(date -u)" >> ~/Documents/one_piece_battles_flutter/lib/config/onepiece_api_config.dart
dart run build_runner build --delete-conflicting-outputs
sed -i '$d' ~/Documents/one_piece_battles_flutter/lib/config/onepiece_api_config.dart
