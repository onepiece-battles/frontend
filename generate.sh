#!/bin/bash
# echo "Removing old api version..."
# rm -rf generated
# mkdir "generated"
echo "building api"
dart run build_runner build --delete-conflicting-outputs

