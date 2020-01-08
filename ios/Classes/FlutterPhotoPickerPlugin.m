#import "FlutterPhotoPickerPlugin.h"
#import <flutter_photo_picker/flutter_photo_picker-Swift.h>

@implementation FlutterPhotoPickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterPhotoPickerPlugin registerWithRegistrar:registrar];
}
@end
