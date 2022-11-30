//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:openapi/src/date_serializer.dart';
import 'package:openapi/src/model/date.dart';

import 'package:openapi/src/model/add_battle_request.dart';
import 'package:openapi/src/model/add_character_request.dart';
import 'package:openapi/src/model/add_fruit_request.dart';
import 'package:openapi/src/model/battle.dart';
import 'package:openapi/src/model/battle_result.dart';
import 'package:openapi/src/model/battle_type.dart';
import 'package:openapi/src/model/character.dart';
import 'package:openapi/src/model/character_type.dart';
import 'package:openapi/src/model/character_type_info.dart';
import 'package:openapi/src/model/eat_fruit_request.dart';
import 'package:openapi/src/model/eat_fruit_response.dart';
import 'package:openapi/src/model/fruit.dart';
import 'package:openapi/src/model/fruit_in_character.dart';
import 'package:openapi/src/model/fruit_type.dart';
import 'package:openapi/src/model/i18n_text.dart';
import 'package:openapi/src/model/list_character_request.dart';
import 'package:openapi/src/model/list_character_response.dart';
import 'package:openapi/src/model/list_fruit_request.dart';
import 'package:openapi/src/model/list_fruit_response.dart';
import 'package:openapi/src/model/login_request.dart';
import 'package:openapi/src/model/login_response.dart';
import 'package:openapi/src/model/logout_request.dart';
import 'package:openapi/src/model/logout_response.dart';
import 'package:openapi/src/model/register_request.dart';
import 'package:openapi/src/model/register_response.dart';
import 'package:openapi/src/model/start_battle_request.dart';
import 'package:openapi/src/model/start_battle_response.dart';
import 'package:openapi/src/model/update_fruit_request.dart';
import 'package:openapi/src/model/user_info.dart';

part 'serializers.g.dart';

@SerializersFor([
  AddBattleRequest,
  AddCharacterRequest,
  AddFruitRequest,
  Battle,
  BattleResult,
  BattleType,
  Character,
  CharacterType,
  CharacterTypeInfo,
  EatFruitRequest,
  EatFruitResponse,
  Fruit,
  FruitInCharacter,
  FruitType,
  I18nText,
  ListCharacterRequest,
  ListCharacterResponse,
  ListFruitRequest,
  ListFruitResponse,
  LoginRequest,
  LoginResponse,
  LogoutRequest,
  LogoutResponse,
  RegisterRequest,
  RegisterResponse,
  StartBattleRequest,
  StartBattleResponse,
  UpdateFruitRequest,
  UserInfo,
])
Serializers serializers = (_$serializers.toBuilder()
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
