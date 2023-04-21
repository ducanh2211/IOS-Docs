
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
      self.image = image
      completionHandler?(true)
    }
    // 3
    PHImageManager.default().requestImage(
      for: asset,
      targetSize: size,
      contentMode: contentMode,
      options: options,
      resultHandler: resultHandler)
  }
}
