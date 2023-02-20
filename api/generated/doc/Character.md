# openapi.model.Character

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**characterTypes** | [**BuiltList&lt;CharacterTypeInfo&gt;**](CharacterTypeInfo.md) | type of fighting skills | [optional] 
**name** | **String** |  | 
**groupOid** | **String** | Which group this character is in. | [optional] 
**hasFruits** | **bool** | Whether this character has eaten fruit | 
**fruits** | [**BuiltList&lt;FruitInCharacter&gt;**](FruitInCharacter.md) |  | [optional] 
**fruitLimit** | **int** | Maximum number of fruit this character can eat. | 
**groupGain** | **int** |  | 
**attack** | **int** |  | 
**defense** | **int** |  | 
**intelligence** | **int** |  | 
**blood** | **int** |  | 
**speed** | **int** |  | 
**magic** | **int** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


