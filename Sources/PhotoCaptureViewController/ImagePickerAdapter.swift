//
//  Copyright (c) 2017 FINN.no AS. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import PhotosUI

public protocol ImagePickerAdapter {
    var maxImageCount: Int {get set}
    // Return a UIViewController suitable for picking one or more images. The supplied selectionHandler may be called more than once.
    // the argument is a dictionary with either (or both) the UIImagePickerControllerOriginalImage or UIImagePickerControllerReferenceURL keys
    // The completion handler will be called when done, supplying the caller with a didCancel flag which will be true
    // if the user cancelled the image selection process.
    // NOTE: The caller is responsible for dismissing any presented view controllers in the completion handler.
    func viewControllerForImageSelection(_ selectedAssetsHandler: @escaping ([Asset]) -> Void, completion: @escaping (Bool) -> Void) -> UIViewController
}

open class ImagePickerControllerAdapter: NSObject, ImagePickerAdapter, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    public var maxImageCount: Int = 5
    
    var selectionHandler: ([Asset]) -> Void = { _ in }
    var completionHandler: (_ didCancel: Bool) -> Void = { _ in }
    
    fileprivate let storage = PhotoStorage()
    
    open func viewControllerForImageSelection(_ selectedAssetsHandler: @escaping ([Asset]) -> Void, completion: @escaping (Bool) -> Void) -> UIViewController {
        selectionHandler = selectedAssetsHandler
        completionHandler = completion
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = (maxImageCount > 0) ? maxImageCount : 0
            configuration.filter = .images
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            return picker
        }
        
        return UIViewController()
    }
    
    // PHPickerViewController Delegate
    @available(iOS 14, *)
    open func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // Track the order of selection
        let dispatchGroup = DispatchGroup()
        var orderedImages: [Asset] = []
        
        for result in results {
            dispatchGroup.enter()
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let uiImage = image as? UIImage {
                        self.createAssetFromImage(uiImage, completion: { (asset: Asset) in
                            var mutableAsset = asset
                            mutableAsset.imageDataSourceType = .library
                            orderedImages.append(mutableAsset)
                            dispatchGroup.leave()
                        })
                        
                       
                    } else {
                        dispatchGroup.leave()
                        print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // `orderedImages` now contains images in the order they were selected
            self.selectionHandler(orderedImages)
            self.completionHandler(false)
        }
        
    }
    
    open func createAssetFromImage(_ image: UIImage, completion: @escaping (Asset) -> Void) {
        storage.createAssetFromImage(image, completion: completion)
    }
}
