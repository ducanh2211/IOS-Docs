
enum AlbumCollectionSectionType: Int, CustomStringConvertible {
  case allPhotos, smartAlbums, userCollections

  var description: String {
    switch self {
    case .allPhotos: return "All Photos"
    case .smartAlbums: return "Smart Albums"
    case .userCollections: return "User Collections"
    }
  }
}
