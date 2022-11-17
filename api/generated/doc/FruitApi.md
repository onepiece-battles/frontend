# openapi.api.FruitApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addFruit**](FruitApi.md#addfruit) | **POST** /api/onepiece/fruit/add | 
[**listFruit**](FruitApi.md#listfruit) | **POST** /api/onepiece/fruit/list | 
[**updateFruit**](FruitApi.md#updatefruit) | **POST** /api/onepiece/fruit/update | 


# **addFruit**
> Fruit addFruit(addFruitRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFruitApi();
final AddFruitRequest addFruitRequest = ; // AddFruitRequest | request to add new fruit to system

try {
    final response = api.addFruit(addFruitRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling FruitApi->addFruit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **addFruitRequest** | [**AddFruitRequest**](AddFruitRequest.md)| request to add new fruit to system | 

### Return type

[**Fruit**](Fruit.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFruit**
> ListFruitResponse listFruit(listFruitRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFruitApi();
final ListFruitRequest listFruitRequest = ; // ListFruitRequest | request to list all fruits available

try {
    final response = api.listFruit(listFruitRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling FruitApi->listFruit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **listFruitRequest** | [**ListFruitRequest**](ListFruitRequest.md)| request to list all fruits available | 

### Return type

[**ListFruitResponse**](ListFruitResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateFruit**
> Fruit updateFruit(updateFruitRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFruitApi();
final UpdateFruitRequest updateFruitRequest = ; // UpdateFruitRequest | request to update fruit

try {
    final response = api.updateFruit(updateFruitRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling FruitApi->updateFruit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateFruitRequest** | [**UpdateFruitRequest**](UpdateFruitRequest.md)| request to update fruit | 

### Return type

[**Fruit**](Fruit.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

