import 'dart:async';

import 'package:flutter/services.dart';

class PhotoPickerAsset {
  int selectedOrder;
  String identifier;
  String type;
  String mimeType;
  String url;
  num width;
  num height;
  String thumbnailUrl;
  num thumbnailWidth;
  num thumbnailHeight;

  PhotoPickerAsset({
    this.selectedOrder,
    this.identifier,
    this.type,
    this.mimeType,
    this.url,
    this.width,
    this.height,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
  });

  factory PhotoPickerAsset.fromJson(Map<dynamic, dynamic> json) {
    if (json == null) return null;

    return PhotoPickerAsset(
      selectedOrder: json['selectedOrder'],
      identifier: json['identifier'],
      type: json['type'],
      mimeType: json['mimeType'],
      url: json['url'],
      width: json['width'],
      height: json['height'],
      thumbnailUrl: json['thumbnailUrl'],
      thumbnailWidth: json['thumbnailWidth'],
      thumbnailHeight: json['thumbnailHeight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedOrder': selectedOrder,
      'identifier': identifier,
      'type': type,
      'mimeType': mimeType,
      'url': url,
      'width': width,
      'height': height,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailWidth': thumbnailWidth,
      'thumbnailHeight': thumbnailHeight,
    };
  }
}

class PhotoPicker {
  static const MethodChannel _channel =
      const MethodChannel('flutter_photo_picker');

  static Future<List<PhotoPickerAsset>> openPicker({
    String mediaType = 'any', // image | video | any
    bool multiple = false,
    int limit = 9,
    int thumbnailMaxWidth = 320,
    int thumbnailMaxHeight = 320,
    int numberOfColumn = 3,
    List<PhotoPickerAsset> selectedAssets,
    Map<dynamic, dynamic> options,
    Map<dynamic, dynamic> messages,
  }) async {
    List<PhotoPickerAsset> assets = [];
    var jsonArray = await _channel.invokeMethod('openPicker', {
      'mediaType': mediaType,
      'multiple': multiple,
      'limit': limit,
      'thumbnailMaxWidth': thumbnailMaxWidth,
      'thumbnailMaxHeight': thumbnailMaxHeight,
      'numberOfColumn': numberOfColumn,
      'selectedAssets': (selectedAssets ?? []).map((v) => v.toJson()).toList(),
      'options': options,
      'messages': messages,
    });

    if (jsonArray != null) {
      Iterable l = jsonArray as List;
      assets = l.map((json) => PhotoPickerAsset.fromJson(json)).toList();
    }

    return assets;
  }
}
