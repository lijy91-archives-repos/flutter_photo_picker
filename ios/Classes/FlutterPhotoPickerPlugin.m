#import "FlutterPhotoPickerPlugin.h"
#if __has_include("flutter_photo_picker-Swift.h")
#import "flutter_photo_picker-Swift.h"
#else
#import <flutter_photo_picker/flutter_photo_picker-Swift.h>
#endif

@implementation FlutterPhotoPickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterPhotoPickerPlugin registerWithRegistrar:registrar];
}
@end
