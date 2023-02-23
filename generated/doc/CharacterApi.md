# openapi.api.CharacterApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addCharacter**](CharacterApi.md#addcharacter) | **POST** /api/onepiece/character/add | 
[**eatFruit**](CharacterApi.md#eatfruit) | **POST** /api/onepiece/character/eat_fruit | 
[**getProfile**](CharacterApi.md#getprofile) | **POST** /api/onepiece/character/get_profile/{id} | 
[**listCharacters**](CharacterApi.md#listcharacters) | **POST** /api/onepiece/character/list | 
[**updateProfile**](CharacterApi.md#updateprofile) | **POST** /api/onepiece/character/update_profile | 


# **addCharacter**
> Character addCharacter(addCharacterRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getCharacterApi();
final AddCharacterRequest addCharacterRequest = ; // AddCharacterRequest | request to add new character to system

try {
    final response = api.addCharacter(addCharacterRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling CharacterApi->addCharacter: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **addCharacterRequest** | [**AddCharacterRequest**](AddCharacterRequest.md)| request to add new character to system | 

### Return type

[**Character**](Character.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **eatFruit**
> EatFruitResponse eatFruit(eatFruitRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getCharacterApi();
final EatFruitRequest eatFruitRequest = ; // EatFruitRequest | request for character to eat fruit

try {
    final response = api.eatFruit(eatFruitRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling CharacterApi->eatFruit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **eatFruitRequest** | [**EatFruitRequest**](EatFruitRequest.md)| request for character to eat fruit | 

### Return type

[**EatFruitResponse**](EatFruitResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProfile**
> Uint8List getProfile(id)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getCharacterApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | character id

try {
    final response = api.getProfile(id);
    print(response);
} catch on DioError (e) {
    print('Exception when calling CharacterApi->getProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| character id | 

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: multipart/form-data

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCharacters**
> ListCharacterResponse listCharacters(listCharacterRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getCharacterApi();
final ListCharacterRequest listCharacterRequest = ; // ListCharacterRequest | request for list all characters

try {
    final response = api.listCharacters(listCharacterRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling CharacterApi->listCharacters: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **listCharacterRequest** | [**ListCharacterRequest**](ListCharacterRequest.md)| request for list all characters | 

### Return type

[**ListCharacterResponse**](ListCharacterResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProfile**
> Uint8List updateProfile(characterId, profileImage)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getCharacterApi();
final String characterId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final MultipartFile profileImage = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.updateProfile(characterId, profileImage);
    print(response);
} catch on DioError (e) {
    print('Exception when calling CharacterApi->updateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **characterId** | **String**|  | [optional] 
 **profileImage** | **MultipartFile**|  | [optional] 

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: image/_*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

