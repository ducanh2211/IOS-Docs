
import UIKit
import Photos
import PhotosUI

class PhotoViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!

  @IBOutlet weak var toolbar: UIToolbar!

  @IBOutlet weak var favoriteButton: UIBarButtonItem!
  @IBAction func favoriteTapped(_ sender: Any) { toggleFavorite() }

  @IBOutlet weak var saveButton: UIBarButtonItem!
  @IBAction func saveTapped(_ sender: Any) { saveImage() }

  @IBOutlet weak var undoButton: UIBarButtonItem!
  @IBAction func undoTapped(_ sender: Any) { undo() }

  @IBAction func applyFilterTapped(_ sender: Any) { applyFilter() }

  // MARK: - Properties
  var asset: PHAsset

  required init?(coder: NSCoder) {
    fatalError("init(coder:) not implemented")
  }

  init?(asset: PHAsset, coder: NSCoder) {
    self.asset = asset
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    getPhoto()
    updateFavoriteButton()
    updateUndoButton()
    saveButton.isEnabled = false
  }

  // MARK: - Functions
  func toggleFavorite() {
    // 1
    let changeHandler: () -> Void = {
      let request = PHAssetChangeRequest(for: self.asset)
      request.isFavorite = !self.asset.isFavorite
    }
    // 2
    PHPhotoLibrary.shared().performChanges(changeHandler, completionHandler: nil)
  }
  
  func updateFavoriteButton() {
    if asset.isFavorite {
      favoriteButton.image = UIImage(systemName: "heart.fill")
    } else {
      favoriteButton.image = UIImage(systemName: "heart")
    }
  }

  func undo() {}
  
  func updateUndoButton() {}

  func applyFilter() {}

  func saveImage() {}

  func getPhoto() {
    imageView.fetchImageAsset(asset, targetSize: view.bounds.size, completionHandler: nil)
  }
}
