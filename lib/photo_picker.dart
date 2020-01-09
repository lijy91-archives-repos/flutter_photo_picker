import 'dart:async';

import 'package:flutter/services.dart';

class PhotoPickerAsset {
  int selectedOrder;
  String type;
  String identifier;
  num width;
  num height;

  PhotoPickerAsset({
    this.selectedOrder,
    this.identifier,
    this.type,
    this.width,
    this.height,
  });

  factory PhotoPickerAsset.fromJson(Map<dynamic, dynamic> json) {
    if (json == null) return null;

    return PhotoPickerAsset(
      selectedOrder: json['selectedOrder'],
      identifier: json['identifier'],
      type: json['type'],
      width: json['width'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedOrder': selectedOrder,
      'identifier': identifier,
      'type': type,
      'width': width,
      'height': height,
    };
  }
}

class PhotoPicker {
  static const MethodChannel _channel =
      const MethodChannel('flutter_photo_picker');

  static Future<List<PhotoPickerAsset>> openPicker({
    String mediaType = 'any', // image | video | any
    bool multiple = false,
    List<PhotoPickerAsset> selectedAssets,
  }) async {
    List<PhotoPickerAsset> assets = [];
    var jsonArray = await _channel.invokeMethod('openPicker', {
      'mediaType': mediaType,
      'multiple': multiple,
      'selectedAssets': (selectedAssets ?? []).map((v) => v.toJson()).toList(),
    });

    if (jsonArray != null) {
      Iterable l = jsonArray as List;
      assets = l.map((json) => PhotoPickerAsset.fromJson(json)).toList();
    }

    return assets;
  }
}
