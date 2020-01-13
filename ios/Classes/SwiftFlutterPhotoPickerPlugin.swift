import Flutter
import UIKit
import Photos
import SVProgressHUD

public class SwiftFlutterPhotoPickerPlugin: NSObject, FlutterPlugin, TLPhotosPickerViewControllerDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_photo_picker", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPhotoPickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var viewController: TLPhotosPickerViewController? = nil
    
    var arguments: NSDictionary? = nil
    var result: FlutterResult? = nil

    var downloadingImageRequestID: PHImageRequestID? = nil

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ((self.result) != nil) {
            self.result!(FlutterError(code: "multiple_request", message: "Cancelled by a second request", details: nil))
            self.result = nil
            return
        }
        
        if (call.method == "openPicker") {
            self.arguments = call.arguments as? NSDictionary
            self.result = result

            self.openPicker()
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func openPicker() {
        let rootViewController = UIApplication.shared.windows.first?.rootViewController
        
        let mediaType: String = self.arguments!["mediaType"] as! String
        let multiple: Bool = self.arguments!["multiple"] as! Bool
        let limit: Int = self.arguments!["limit"] as! Int
        let numberOfColumn: Int = self.arguments!["numberOfColumn"] as! Int
        let selectedAssets: Array<NSDictionary> = self.arguments!["selectedAssets"] as! Array<NSDictionary>
        let options: NSDictionary? = self.arguments!["options"] as? NSDictionary
        
        var configure = TLPhotosPickerConfigure()
        
        if (mediaType == "image") {
            configure.mediaType = PHAssetMediaType.image
        } else if (mediaType == "video") {
            configure.mediaType = PHAssetMediaType.video
        }

        configure.singleSelectedMode = !multiple
        configure.maxSelectedAssets = limit
        configure.numberOfColumn = numberOfColumn
        configure.autoPlay = false
        configure.usedCameraButton = mediaType != "video"
        
        if (options != nil) {
            if let tapHereToChange = options?["tapHereToChange"] {
                configure.tapHereToChange = tapHereToChange as! String
            }
            if let cancelTitle = options?["cancelTitle"] {
                configure.cancelTitle = cancelTitle as! String
            }
            if let doneTitle = options?["doneTitle"] {
                configure.doneTitle = doneTitle as! String
            }
            if let emptyMessage = options?["emptyMessage"] {
                configure.emptyMessage = emptyMessage as! String
            }
            if let customLocalizedTitle = options?["customLocalizedTitle"] {
                configure.customLocalizedTitle = customLocalizedTitle as! [String: String]
            }
        }

        self.viewController = TLPhotosPickerViewController()
        self.viewController?.modalPresentationStyle = .fullScreen
        self.viewController?.delegate = self
        self.viewController?.configure = configure
        self.viewController?.selectedAssets = selectedAssets.map { (asset: NSDictionary) -> TLPHAsset in
            var tlphAsset: TLPHAsset = TLPHAsset.asset(with: asset["identifier"] as! String)!
            tlphAsset.selectedOrder = asset["selectedOrder"] as! Int
            return tlphAsset
        }

        rootViewController?.present(viewController!, animated: true, completion: nil)
    }
    
    // TLPhotosPickerViewControllerDelegate
    public func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                SVProgressHUD.show(withStatus: self.t("Processing..."))
            }
            
            let cachingImageManager = PHCachingImageManager()
            let fileManager = FileManager.default
            let temporaryDirectory = NSTemporaryDirectory()

            var medias: Array<NSDictionary> = Array<NSDictionary>()
            for asset in withTLPHAssets {
                let media: NSMutableDictionary = NSMutableDictionary()
                
                media.setObject(asset.selectedOrder, forKey: NSString("selectedOrder"))
                media.setObject(asset.phAsset!.localIdentifier, forKey: NSString("identifier"))
                media.setObject(asset.originalFileName!, forKey: NSString("filename"))
                media.setObject(asset.phAsset!.pixelWidth, forKey: NSString("width"))
                media.setObject(asset.phAsset!.pixelHeight, forKey: NSString("height"))
                if (asset.type == .photo) {
                    media.setObject("image", forKey: NSString("type"))
                } else if (asset.type == .video) {
                    media.setObject("video", forKey: NSString("type"))
                }

                let semaphore = DispatchSemaphore(value: 0)
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
                        
                        let cachingImageRequestOptions: PHImageRequestOptions = PHImageRequestOptions()
                        cachingImageRequestOptions.isSynchronous = true

                        let thumbnailMaxWidth = self.arguments!["thumbnailMaxWidth"] as? Int ?? 320
                        let thumbnailMaxHeight = self.arguments!["thumbnailMaxHeight"] as? Int ?? 320
                        
                        let targetSize = CGSize(width: thumbnailMaxWidth, height: thumbnailMaxHeight)

                        cachingImageManager.requestImage(for: asset.phAsset!, targetSize: targetSize, contentMode: .aspectFit, options: cachingImageRequestOptions) { (image, info) in
                            let thumbnailImagePath = NSString(format: "%@%@-thumbnail.jpg", temporaryDirectory, asset.originalFileName!) as String
                            let thumbnailImageURL: URL = URL(fileURLWithPath: thumbnailImagePath)
                            if (fileManager.fileExists(atPath: thumbnailImagePath)) {
                                try! fileManager.removeItem(atPath: thumbnailImagePath)
                            }
                            
                            if let imageData = image!.jpegData(compressionQuality: 1.0) {
                                try? imageData.write(to: thumbnailImageURL)
                            }
                            
                            media.setObject(thumbnailImageURL.absoluteString, forKey: NSString("thumbnailUrl"))
                            media.setObject(image!.size.width, forKey: NSString("thumbnailWidth"))
                            media.setObject(image!.size.height, forKey: NSString("thumbnailHeight"))

                            medias.append(media)
                            
                            semaphore.signal()
                        }
                    }
                )

                semaphore.wait(timeout: .distantFuture)
            }

            DispatchQueue.main.async {
                self.result!(medias)
                self.result = nil

                SVProgressHUD.dismiss()
            }
        }
    }

    public func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
    }

    public func photoPickerDidCancel() {
        self.result!(FlutterError(code: "cancelled", message: "Operation cancelled by user", details: nil))
        self.result = nil
    }

    public func dismissComplete() {
    }

    public func canSelectAsset(phAsset: PHAsset) -> Bool {
        var locallyAvailable: Bool = true
        
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = true
        
        PHImageManager.default().requestImageData(for: phAsset, options: imageRequestOptions) { (imageData, _, _, info) in
            let info = info as! [String: AnyObject]
            if (info.keys.contains(PHImageResultIsInCloudKey)) {
                locallyAvailable = !(info[PHImageResultIsInCloudKey] as! Bool)
            } else if (imageData == nil) {
                locallyAvailable = false
            }
        }

        if (!locallyAvailable) {
            DispatchQueue.main.async {
                if (self.downloadingImageRequestID != nil) {
                    let alert = UIAlertController(title: "", message: self.t("Waiting image/video download to complete"), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: self.t("Ok"), style: .default, handler: nil))
                    self.viewController?.present(alert, animated: true, completion: nil)

                    return
                }
                SVProgressHUD.show()
                var tlphAsset: TLPHAsset = TLPHAsset.asset(with: phAsset.localIdentifier)!
                self.downloadingImageRequestID = tlphAsset.cloudImageDownload(
                    progressBlock: { (progress) in
                        print(progress)
                        if (progress > 0) {
                            SVProgressHUD.showProgress(Float(progress))
                        }
                    },
                    completionBlock: { (image) in
                        SVProgressHUD.dismiss()

                        tlphAsset.selectedOrder = (self.viewController?.selectedAssets.count)! + 1;
                        self.viewController?.selectedAssets.append(tlphAsset)
                        self.viewController?.logDelegate?.selectedPhoto(picker: self.viewController!, at: tlphAsset.selectedOrder)

                        self.downloadingImageRequestID = nil
                    }
                )
            }
        }
        
        return locallyAvailable
    }

    public func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: t("Exceed Maximum Number Of Selection"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: t("Ok"), style: .default, handler: nil))
        picker.present(alert, animated: true, completion: nil)
    }
    
    public func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        picker.dismiss(animated: true) {
            let alert = UIAlertController(title: "", message: self.t("Denied albums permissions granted"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: self.t("Ok"), style: .default, handler: nil))
            picker.present(alert, animated: true, completion: nil)
        }
    }
    
    public func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: t("Denied camera permissions granted"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: t("Ok"), style: .default, handler: nil))
        picker.present(alert, animated: true, completion: nil)
    }
    
    private func t(_ message: String) -> String {
        let messages: NSDictionary? = self.arguments!["messages"] as? NSDictionary
        
        if let m = messages?[message] {
            return m as! String
        }
        
        return message
    }
}
