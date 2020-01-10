#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_photo_picker'
  s.version          = '0.0.1'
  s.summary          = 'Photo Picker plugin for Flutter.'
  s.description      = <<-DESC
  Photo Picker plugin for Flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LiJianying' => 'lijy91@foxmail.com' }
  s.source           = { :path => '.' }
  s.resource = 'Classes/TLPhotoPicker/TLPhotoPickerController.bundle'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'SVProgressHUD'
  s.platform = :ios, '9.1'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end

