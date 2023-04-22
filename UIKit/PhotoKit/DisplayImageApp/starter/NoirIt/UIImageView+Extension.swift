
import UIKit
import Photos

extension UIImageView {
  func fetchImageAsset(_ asset: PHAsset?,
                       targetSize size: CGSize,
                       contentMode: PHImageContentMode = .aspectFill,
                       options: PHImageRequestOptions? = nil,
                       completionHandler: ((Bool) -> Void)?) {
    
    // 1
    guard let asset = asset else {
      completionHandler?(false)
      return
    }
    // 2
    let resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void = { image, info in
      print("result handler thread: \(Thread.current)")
      if let image = image {
        self.image = image
        print("sucess thread: \(Thread.current)")
        completionHandler?(true)
      }
    }
    
    
    
    let option = PHImageRequestOptions()
    option.isSynchronous = false
    option.deliveryMode = .opportunistic
    
    let manager = PHCachingImageManager()
    
//    PHCachingImageManager().startCachingImages(for: [asset], targetSize: size, contentMode: contentMode, options: option)
    
    manager.requestImage(
      for: asset,
      targetSize: size,
      contentMode: contentMode,
      options: option,
      resultHandler: resultHandler)
    
    print("request image thead: \(Thread.current)")

  }
}

/*
 highQualityFormat:
 true: null / false: main
 opportunistic:
 true: null / false: null - main
 fastFormat:
 true: null / false: main
 */
