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

class AlbumCollectionViewController: UICollectionViewController {
  var sections: [AlbumCollectionSectionType] = [.all, .smartAlbums, .userCollections]
  var allPhotos = PHFetchResult<PHAsset>()
  var smartAlbums = PHFetchResult<PHAssetCollection>()
  var userCollections = PHFetchResult<PHAssetCollection>()

  override func viewDidLoad() {
    super.viewDidLoad()
    getPermissionIfNecessary { granted in
      guard granted else { return }
      self.fetchAssets()
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
    }
    PHPhotoLibrary.shared().register(self)
  }

  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }

  @IBSegueAction func makePhotosCollectionViewController(_ coder: NSCoder) -> PhotosCollectionViewController? {
    guard
      let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first
      else { return nil }

    let sectionType = sections[selectedIndexPath.section]
    let item = selectedIndexPath.item

    let assets: PHFetchResult<PHAsset>
    let title: String

    switch sectionType {
    case .all:
      assets = allPhotos
      title = AlbumCollectionSectionType.all.description
    case .smartAlbums, .userCollections:
      let album =
        sectionType == .smartAlbums ? smartAlbums[item] : userCollections[item]
      assets = PHAsset.fetchAssets(in: album, options: nil)
      title = album.localizedTitle ?? ""
    }

    return PhotosCollectionViewController(assets: assets, title: title, coder: coder)
  }

  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if kind == UICollectionView.elementKindSectionHeader {
      guard let headerView = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: AlbumCollectionReusableView.reuseIdentifier,
        for: indexPath) as? AlbumCollectionReusableView
        else {
        fatalError("Unable to dequeue AlbumCollectionReusableView")
      }
      headerView.title.text = sections[indexPath.section].description
      return headerView
    }
    return UICollectionReusableView()
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // 1
    guard let cell =
      collectionView.dequeueReusableCell(
        withReuseIdentifier: AlbumCollectionViewCell.reuseIdentifier,
        for: indexPath) as? AlbumCollectionViewCell
    else {
      fatalError("Unable to dequeue AlbumCollectionViewCell")
    }
    // 2
    var coverAsset: PHAsset?
    let sectionType = sections[indexPath.section]
    switch sectionType {
    // 3
    case .all:
      coverAsset = allPhotos.firstObject
      cell.update(title: sectionType.description, count: allPhotos.count)
    // 4
    case .smartAlbums, .userCollections:
      let collection = sectionType == .smartAlbums ?
        smartAlbums[indexPath.item] :
        userCollections[indexPath.item]
      let fetchedAssets = PHAsset.fetchAssets(in: collection, options: nil)
      coverAsset = fetchedAssets.firstObject
      cell.update(title: collection.localizedTitle, count: fetchedAssets.count)
    }
    // 5
    guard let asset = coverAsset else { return cell }
    cell.photoView.fetchImageAsset(asset, targetSize: cell.bounds.size) { success in
      cell.photoView.isHidden = !success
      cell.emptyView.isHidden = success
    }
    return cell
  }

  func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
    // 1
    guard PHPhotoLibrary.authorizationStatus() != .authorized else {
      completionHandler(true)
      return
    }
    // 2
    PHPhotoLibrary.requestAuthorization { status in
      completionHandler(status == .authorized ? true : false)
    }
  }

  func fetchAssets() {// 1
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [
      NSSortDescriptor(
        key: "creationDate",
        ascending: false)
    ]
    // 2
    allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    // 3
    smartAlbums = PHAssetCollection.fetchAssetCollections(
      with: .smartAlbum,
      subtype: .albumRegular,
      options: nil)
    // 4
    userCollections = PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .albumRegular,
      options: nil)
  }

  override func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    switch sections[section] {
    case .all: return 1
    case .smartAlbums: return smartAlbums.count
    case .userCollections: return userCollections.count
    }
  }
}

extension AlbumCollectionViewController: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    DispatchQueue.main.sync {
      // 1
      if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
        allPhotos = changeDetails.fetchResultAfterChanges
      }
      // 2
      if let changeDetails = changeInstance.changeDetails(for: smartAlbums) {
        smartAlbums = changeDetails.fetchResultAfterChanges
      }
      if let changeDetails = changeInstance.changeDetails(for: userCollections) {
        userCollections = changeDetails.fetchResultAfterChanges
      }
      // 4
      collectionView.reloadData()
    }
  }
}
