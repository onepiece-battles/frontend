import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
  additionalProperties: AdditionalProperties(
      pubAuthor: "yichi zhang", pubAuthorEmail: "onepiecebattles@163.com"),
  inputSpecFile: "onepiece-battles-api/api/openapi.yaml",
  generatorName: Generator.dart,
  outputDirectory: 'generated',
)
class OnepieceApiConfig {}
