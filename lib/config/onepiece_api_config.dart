import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
    additionalProperties: AdditionalProperties(
        pubAuthor: "yichi zhang", pubAuthorEmail: "onepiecebattles@163.com"),
    inputSpec: InputSpec(path: "onepiece-battles-api/api/openapi.yaml"),
    generatorName: Generator.dart,
    skipIfSpecIsUnchanged: false,
    outputDirectory: 'generated')
class OnepieceApiConfig {}