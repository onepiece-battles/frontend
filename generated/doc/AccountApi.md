# openapi.api.AccountApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**login**](AccountApi.md#login) | **POST** /api/onepiece/account/login | 
[**logout**](AccountApi.md#logout) | **POST** /api/onepiece/account/logout | 
[**register**](AccountApi.md#register) | **POST** /api/onepiece/account/register | 


# **login**
> LoginResponse login(loginRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAccountApi();
final LoginRequest loginRequest = ; // LoginRequest | request to login to system.

try {
    final response = api.login(loginRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling AccountApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)| request to login to system. | 

### Return type

[**LoginResponse**](LoginResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> LogoutResponse logout(logoutRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAccountApi();
final LogoutRequest logoutRequest = ; // LogoutRequest | request to logout from system

try {
    final response = api.logout(logoutRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling AccountApi->logout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutRequest** | [**LogoutRequest**](LogoutRequest.md)| request to logout from system | 

### Return type

[**LogoutResponse**](LogoutResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register**
> RegisterResponse register(registerRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAccountApi();
final RegisterRequest registerRequest = ; // RegisterRequest | request to register new account.

try {
    final response = api.register(registerRequest);
    print(response);
} catch on DioError (e) {
    print('Exception when calling AccountApi->register: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)| request to register new account. | 

### Return type

[**RegisterResponse**](RegisterResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

