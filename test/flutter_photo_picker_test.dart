import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_photo_picker/flutter_photo_picker.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_photo_picker');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterPhotoPicker.platformVersion, '42');
  });
}
