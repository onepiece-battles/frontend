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
// Wed Jan 10 09:29:26 UTC 2024
// Wed Jan 10 09:30:18 UTC 2024
