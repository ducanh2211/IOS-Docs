/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

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

  var asset: PHAsset
  var editingOutput: PHContentEditingOutput?

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
    PHPhotoLibrary.shared().register(self)
  }

  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }

  func updateFavoriteButton() {
    if asset.isFavorite {
      favoriteButton.image = UIImage(systemName: "heart.fill")
    } else {
      favoriteButton.image = UIImage(systemName: "heart")
    }
  }

  func updateUndoButton() {
    let adjustmentResources = PHAssetResource.assetResources(for: asset)
      .filter { $0.type == .adjustmentData }
    undoButton.isEnabled = !adjustmentResources.isEmpty
  }

  func toggleFavorite() {
    // 1
    let changeHandler: () -> Void = {
      let request = PHAssetChangeRequest(for: self.asset)
      request.isFavorite = !self.asset.isFavorite
    }
    // 2
    PHPhotoLibrary.shared().performChanges(changeHandler, completionHandler: nil)
  }

  func applyFilter() {
    // 1
    asset.requestContentEditingInput(with: nil) { input, _ in
      // 2
      guard let bundleID = Bundle.main.bundleIdentifier else {
        fatalError("Error: unable to get bundle identifier")
      }
      guard let input = input else {
        fatalError("Error: cannot get editing input")
      }
      guard let filterData = Filter.noir.data else {
        fatalError("Error: cannot get filter data")
      }
      // 3
      let adjustmentData = PHAdjustmentData(
        formatIdentifier: bundleID,
        formatVersion: "1.0",
        data: filterData)
      // 4
      self.editingOutput = PHContentEditingOutput(contentEditingInput: input)
      guard let editingOutput = self.editingOutput else { return }
      editingOutput.adjustmentData = adjustmentData
      // 5
      let fitleredImage = self.imageView.image?.applyFilter(.noir)
      self.imageView.image = fitleredImage
      // 6
      let jpegData = fitleredImage?.jpegData(compressionQuality: 1.0)
      do {
        try jpegData?.write(to: editingOutput.renderedContentURL)
      } catch {
        print(error.localizedDescription)
      }
      // 7
      DispatchQueue.main.async {
        self.saveButton.isEnabled = true
      }
    }
  }

  func saveImage() {
    // 1
    let changeRequest: () -> Void = {
      let changeRequest = PHAssetChangeRequest(for: self.asset)
      changeRequest.contentEditingOutput = self.editingOutput
    }
    // 2
    let completionHandler: (Bool, Error?) -> Void = { success, error in
      guard success else {
        print("Error: cannot edit asset: \(String(describing: error))")
        return
      }
      // 3
      self.editingOutput = nil
      DispatchQueue.main.async {
        self.saveButton.isEnabled = false
      }
    }
    // 4
    PHPhotoLibrary.shared().performChanges(
      changeRequest,
      completionHandler: completionHandler)
  }

  func undo() {
    // 1
    let changeRequest: () -> Void = {
      let request = PHAssetChangeRequest(for: self.asset)
      request.revertAssetContentToOriginal()
    }
    // 2
    let completionHandler: (Bool, Error?) -> Void = { success, error in
      guard success else {
        print("Error: can't revert the asset: \(String(describing: error))")
        return
      }
      DispatchQueue.main.async {
        self.undoButton.isEnabled = false
      }
    }
    // 3
    PHPhotoLibrary.shared().performChanges(
      changeRequest,
      completionHandler: completionHandler)
  }

  func getPhoto() {
    imageView.fetchImageAsset(asset, targetSize: view.bounds.size, completionHandler: nil)
  }
}

// 1
extension PhotoViewController: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    // 2
    guard
      let change = changeInstance.changeDetails(for: asset),
      let updatedAsset = change.objectAfterChanges
      else { return }
    // 3
    DispatchQueue.main.sync {
      // 4
      asset = updatedAsset
      imageView.fetchImageAsset(
        asset,
        targetSize: view.bounds.size
      ) { [weak self] _ in
        guard let self = self else { return }
        // 5
        self.updateFavoriteButton()
        self.updateUndoButton()
      }
    }
  }
}
