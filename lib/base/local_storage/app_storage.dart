
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final appStorage = Provider((ref) => AppStorage._());

class AppStorage{
  late FlutterSecureStorage _storage;

  AppStorage._(){
     _storage = FlutterSecureStorage(aOptions: AndroidOptions(
       encryptedSharedPreferences: true,
     ));
  }

  Future<String?> read(String key) async{
    return await _storage.read(key: key);
  }
  Future write({required String key, required String value}) async{
    await _storage.write(key: key, value: value);
  }
  Future<T?> readObject<T>(String key, T Function(Map<String, dynamic>) converter) async{
    try{
      final str = await read(key);
      if(str == null || str.isEmpty){
        return null;
      }

      final map = jsonDecode(str);
      return converter(map);
    }catch(e){
      return null;
    }
  }
  Future storeObject({required String key, required Map value}) async{
    write(key: key, value: jsonEncode(value));
  }
  Future deleteAll() async{
    await _storage.deleteAll();
  }
}