import Flutter
import UIKit
import TLPhotoPicker
import Photos

public class SwiftFlutterPhotoPickerPlugin: NSObject, FlutterPlugin, TLPhotosPickerViewControllerDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_photo_picker", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPhotoPickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var result: FlutterResult? = nil

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ((self.result) != nil) {
            self.result!(FlutterError(code: "multiple_request", message: "Cancelled by a second request", details: nil))
            self.result = nil
        }
        
        if (call.method == "openPicker") {
            self.result = result

            self.openPicker(call.arguments as! NSDictionary)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func openPicker(_ arguments: NSDictionary) {
        let rootViewController = UIApplication.shared.windows.first?.rootViewController
        
        let mediaType: String = arguments["mediaType"] as! String
        let multiple: Bool = arguments["multiple"] as! Bool
        let selectedAssets: Array<NSDictionary> = arguments["selectedAssets"] as! Array<NSDictionary>
        
        var configure = TLPhotosPickerConfigure()
        
        if (mediaType == "image") {
            configure.mediaType = PHAssetMediaType.image
        } else if (mediaType == "video") {
            configure.mediaType = PHAssetMediaType.video
        }

        configure.singleSelectedMode = !multiple

        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        viewController.configure = configure
        viewController.selectedAssets = selectedAssets.map { (asset: NSDictionary) -> TLPHAsset in
            var tlphAsset: TLPHAsset = TLPHAsset.asset(with: asset["identifier"] as! String)!
            tlphAsset.selectedOrder = asset["selectedOrder"] as! Int
            return tlphAsset
        }

        rootViewController?.present(viewController, animated: true, completion: nil)
    }
    
    // TLPhotosPickerViewControllerDelegate
    public func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        DispatchQueue.global().async {
            var medias: Array<NSDictionary> = Array<NSDictionary>()
            for asset in withTLPHAssets {
                let media: NSMutableDictionary = NSMutableDictionary()
                
                media.setObject(asset.selectedOrder, forKey: NSString("selectedOrder"))
                media.setObject(asset.phAsset!.localIdentifier, forKey: NSString("identifier"))
                media.setObject(asset.phAsset!.pixelWidth, forKey: NSString("width"))
                media.setObject(asset.phAsset!.pixelHeight, forKey: NSString("height"))
                if (asset.type == .photo) {
                    media.setObject("image", forKey: NSString("type"))
                } else if (asset.type == .video) {
                    media.setObject("video", forKey: NSString("type"))
                }
                
                let tempCopyMediaFileGroup = DispatchGroup()
                var tempCopyMediaFileCompleted: Bool = false

                asset.tempCopyMediaFile(
                    videoRequestOptions: nil,
                    imageRequestOptions: nil,
                    livePhotoRequestOptions: nil,
                    exportPreset: AVAssetExportPresetHighestQuality,
                    convertLivePhotosToJPG: true,
                    progressBlock: { (progress) in
                        print(progress)
                    },
                    completionBlock: { (url, mimeType) in
                        media.setObject(url.absoluteString, forKey: NSString("url"))
                        media.setObject(mimeType, forKey: NSString("mimeType"))
                        
                        tempCopyMediaFileCompleted = true
                    }
                )
                
                tempCopyMediaFileGroup.enter()
                DispatchQueue.global().async {
                    while !tempCopyMediaFileCompleted { sleep(1) }
                    tempCopyMediaFileGroup.leave()
                }
                tempCopyMediaFileGroup.wait()

                medias.append(media)
            }
            
            print(medias)

            self.result!(medias)
            self.result = nil
        }
    }

    public func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
    }

    public func photoPickerDidCancel() {
        self.result!(nil)
        self.result = nil
    }

    public func dismissComplete() {
    }

    public func canSelectAsset(phAsset: PHAsset) -> Bool {
        let assetResources = PHAssetResource.assetResources(for: phAsset)
        let locallyAvailable = assetResources.first?.value(forKey: "locallyAvailable") as! Bool
        
        if (!locallyAvailable) {
            let tlphAsset: TLPHAsset = TLPHAsset.asset(with: phAsset.localIdentifier)!
            tlphAsset.cloudImageDownload(
                progressBlock: { (progress) in
                    print(progress)
                },
                completionBlock: { (image) in
                    print(">>>")
                }
            )
        }
        
        return locallyAvailable
    }

    public func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        // exceed max selection
    }

    public func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        // handle denied albums permissions case
    }

    public func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        // handle denied camera permissions case
    }
}
