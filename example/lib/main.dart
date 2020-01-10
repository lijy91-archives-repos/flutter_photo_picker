import 'package:flutter/material.dart';

import 'package:flutter_photo_picker/flutter_photo_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  List<PhotoPickerAsset> _selectedAssets = [];

  void _handleClickOpenPicker() async {
    List<PhotoPickerAsset> assets = await PhotoPicker.openPicker(
      mediaType: 'any',
      multiple: true,
      limit: 3,
      selectedAssets: _selectedAssets,
      messages: {
        "Ok": "确定",
        "Processing...": "处理中...",
        "Exceed Maximum Number Of Selection": "超过最大选择数",
        "Denied albums permissions granted": "已拒绝授予相册权限",
        "Denied camera permissions granted": "已拒绝授予相机权限",
        "Waiting image/video download to complete": "等待图像/视频下载完成",
      },
      options: {
        'tapHereToChange': '点击此处以更改',
        'cancelTitle': '取消',
        'doneTitle': '完成',
        'emptyMessage': '没有相册',
        'customLocalizedTitle': {
          'Camera Roll': '相机相册',
          'Recents': '最近使用',
          'Selfies': '自拍',
          'Videos': '视频'
        }
      }
    );

    setState(() {
      print(assets);
      _selectedAssets = assets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Photo picker example'),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Open Picker'),
              onTap: _handleClickOpenPicker,
            ),
            Text(
              '${_selectedAssets.length}'
            ),
            Text(
              '${_selectedAssets.map((v) => v.toJson()).join('\n').toString()}'
            )
          ],
        )
      ),
    );
  }
}
