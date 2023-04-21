
import UIKit
import Photos

class AlbumCollectionViewController: UICollectionViewController {
  
  // MARK: - Properties
  var sections: [AlbumCollectionSectionType] = [.allPhotos, .smartAlbums, .userCollections]
  
  private var allPhotos = PHFetchResult<PHAsset>()
  private var smartAlbums = PHFetchResult<PHAssetCollection>()
  private var userCollections = PHFetchResult<PHAssetCollection>()

  // MARK: - Life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    getPermissionIfNecessary { granted in
      guard granted else { return }
      self.fetchAssets()
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
    }
  }

  // MARK: - Functions
  @IBSegueAction func makePhotosCollectionViewController(_ coder: NSCoder) -> PhotosCollectionViewController? {
    // 1
    guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else { return nil }

    // 2
    let sectionType = sections[selectedIndexPath.section]
    let item = selectedIndexPath.item
    
    // 3
    let assets: PHFetchResult<PHAsset>
    let title: String

    switch sectionType {
    // 4
    case .allPhotos:
      assets = allPhotos
      title = AlbumCollectionSectionType.allPhotos.description
    // 5
    case .smartAlbums, .userCollections:
      let album =
        sectionType == .smartAlbums ? smartAlbums[item] : userCollections[item]
      assets = PHAsset.fetchAssets(in: album, options: nil)
      title = album.localizedTitle ?? ""
    }

    // 6
    return PhotosCollectionViewController(assets: assets, title: title, coder: coder)
  }

  func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
    // check xem da authorized photo permission chua
    guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else {
      print(Thread.current)
      completionHandler(true)
      return
    } 
    // Neu chua authorized thi se gui request
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      switch status {
        case .authorized:
          completionHandler(true)
        case .notDetermined, .restricted, .denied, .limited:
          completionHandler(false)
        @unknown default:
          completionHandler(false)
      }
    }
  }

  func fetchAssets() {
    // 1
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [
      NSSortDescriptor(key: "creationDate", ascending: false)
    ]
    // 2
    allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    
    // 3
    smartAlbums = PHAssetCollection.fetchAssetCollections(
      with: PHAssetCollectionType.smartAlbum,
      subtype: PHAssetCollectionSubtype.albumRegular,
      options: nil)
    // 4
    userCollections = PHAssetCollection.fetchAssetCollections(
      with: PHAssetCollectionType.album,
      subtype: PHAssetCollectionSubtype.albumRegular,
      options: nil)
  }
}

// MARK: - UICollectionViewDatasource
extension AlbumCollectionViewController {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    switch sections[section] {
      case .allPhotos: return 1
      case .smartAlbums: return smartAlbums.count
      case .userCollections: return userCollections.count
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // 1
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: AlbumCollectionViewCell.reuseIdentifier,
      for: indexPath) as! AlbumCollectionViewCell
    
    // 2
    var coverAsset: PHAsset?
    let sectionType = sections[indexPath.section]
    
    switch sectionType {
    // 3
    case .allPhotos:
      coverAsset = allPhotos.firstObject
      cell.update(title: sectionType.description, count: allPhotos.count)
    // 4
    case .smartAlbums, .userCollections:
      let collection = (sectionType == .smartAlbums)
        ? smartAlbums[indexPath.item]
        : userCollections[indexPath.item]
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
  
}
