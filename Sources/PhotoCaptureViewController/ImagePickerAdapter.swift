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
    func viewControllerForImageSelection(_ selectedAssetsHandler: @escaping ([UIImage]) -> Void, completion: @escaping (Bool) -> Void) -> UIViewController
}

open class ImagePickerControllerAdapter: NSObject, ImagePickerAdapter, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    public var maxImageCount: Int = 5
    
    var selectionHandler: ([UIImage]) -> Void = { _ in }
    var completionHandler: (_ didCancel: Bool) -> Void = { _ in }
    
    open func viewControllerForImageSelection(_ selectedAssetsHandler: @escaping ([UIImage]) -> Void, completion: @escaping (Bool) -> Void) -> UIViewController {
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
        
        var selectedImages: [UIImage] = []
        
        let itemProviders = results.map(\.itemProvider)
        for itemProvider in itemProviders where itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let error = error {
                    print("Error loading image: \(error)")
                } else if let image = image as? UIImage {
                    selectedImages.append(image)
                }
            }
        }
        
        print("didFinishPicking:",selectedImages)
        
        selectionHandler(selectedImages)
        completionHandler(false)
        
    }
}
