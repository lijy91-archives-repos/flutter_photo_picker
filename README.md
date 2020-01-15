# flutter_photo_picker

Photo Picker plugin for Flutter.

## Getting Started

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  flutter_photo_picker:
    git:
      url: https://github.com/blankapp/flutter_photo_picker.git
      ref: master
```

Change your project `ios/Podfile` file according to the example:

```diff
# Uncomment this line to define a global platform for your project
-# platform :ios, '8.0'
+platform :ios, '9.1'
```

You can install packages from the command line:

```bash
$ flutter packages get
```

### Usage

```dart
import 'package:flutter_photo_picker/flutter_photo_picker.dart';

List<PhotoPickerAsset> assets = await PhotoPicker.openPicker(
  mediaType: 'any', // image | video | any
  multiple: true,
  limit: 3,
);
```

## Related Links

- https://github.com/tilltue/TLPhotoPicker
- https://github.com/zhihu/Matisse

## License

```
MIT License

Copyright (c) 2020 LiJianying <lijy91@foxmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
