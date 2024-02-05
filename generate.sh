#!/bin/bash
echo "checking directory condition"
cd generated || exit 1
find . -type d -mindepth 1 -exec rm -rf {} \;
cd ..
echo "All directories are deleted"
echo "start generating files..."
# shellcheck disable=SC2088
FILE="lib/config/onepiece_api_config.dart"
echo "// $(date -u)" >> $FILE
dart run build_runner build --delete-conflicting-outputs
git restore $FILE
