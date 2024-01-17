import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
  additionalProperties: AdditionalProperties(
      pubAuthor: "yichi zhang", pubAuthorEmail: "onepiecebattles@163.com"),
  inputSpecFile: "onepiece-battles-api/api/openapi.yaml",
  generatorName: Generator.dart,
  outputDirectory: 'generated',
  alwaysRun: true
)
class OnepieceApiConfig {}
// Thu Jan 11 09:37:27 UTC 2024
// Fri Jan 12 03:18:57 UTC 2024
// Tue Jan 16 06:24:08 UTC 2024
// Wed Jan 17 08:19:27 UTC 2024
// Wed Jan 17 08:23:32 UTC 2024
// Wed Jan 17 09:03:16 UTC 2024
