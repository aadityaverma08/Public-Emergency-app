import 'dart:math';

class Keys {
  static final Keys _instance = Keys._internal();
  factory Keys() => _instance;
  Keys._internal();

  final int appId = 1883588979;
  final String appSign = "2b9d49eb04b1dd96f17892d017c2d9e0ce4f22c976edf6d5d62fe7483c4917c4";
  final String userId = Random().nextInt(100000).toString();
}
