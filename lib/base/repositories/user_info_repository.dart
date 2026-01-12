
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_storage/app_storage.dart';
import '../models/user.dart';


final userInfoRepository = ChangeNotifierProvider(
      (ref) => UserInfoRepository(ref.read(appStorage)),
);

class UserInfoRepository extends ChangeNotifier {
  final AppStorage storage;
  User? _user;
  User? get user => _user;

  String? _accessToken;
  String? get accessToken => _accessToken;


  UserInfoRepository(this.storage) {
    _init();
  }

  _init() async {
    //_accessToken = await storage.read(accessTokenKey);
    //_user = await storage.readObject(userKey, (m) => User.fromJson(m));

    ///
    /// TODO: Initialize all fields
    ///

    notifyListeners();
  }

  setUser(User user) {
    _user = user;
    //storage.storeObject(key: userKey, value: user.toJson());
    notifyListeners();
  }

  setAccessToken(String accessToken) {
    _accessToken = accessToken;
    //storage.write(key: accessTokenKey, value: accessToken);
    notifyListeners();
  }

  deleteAll() {
    storage.deleteAll();//check if this is needed
    _accessToken = '';
    _user = null;

    ///
    /// release other fields
    ///

    notifyListeners();
  }
}
