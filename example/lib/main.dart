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
      mediaType: 'image',
      selectedAssets: _selectedAssets,
    );

    setState(() {
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
            )
          ],
        )
      ),
    );
  }
}
