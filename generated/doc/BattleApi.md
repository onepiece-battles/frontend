# openapi.api.BattleApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addBattle**](BattleApi.md#addbattle) | **POST** /api/onepiece/battle/add | 
[**startBattle**](BattleApi.md#startbattle) | **POST** /api/onepiece/battle/start_battle | 


# **addBattle**
> Battle addBattle(addBattleRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getBattleApi();
final AddBattleRequest addBattleRequest = ; // AddBattleRequest | request to create a battle

try {
    final response = api.addBattle(addBattleRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling BattleApi->addBattle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **addBattleRequest** | [**AddBattleRequest**](AddBattleRequest.md)| request to create a battle | 

### Return type

[**Battle**](Battle.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startBattle**
> StartBattleResponse startBattle(startBattleRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getBattleApi();
final StartBattleRequest startBattleRequest = ; // StartBattleRequest | request to start a battle by battle id.

try {
    final response = api.startBattle(startBattleRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling BattleApi->startBattle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startBattleRequest** | [**StartBattleRequest**](StartBattleRequest.md)| request to start a battle by battle id. | 

### Return type

[**StartBattleResponse**](StartBattleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

