#!/bin/bash
echo "Removing old api version..."
rm -rf generated
mkdir "generated"
echo "building api"
java -jar openapi-generator-cli-5.3.1.jar generate -i onepiece-battles-api/api/openapi.yaml -g dart-dio-next  -o generated/
cd generated

# flutter pub get
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

