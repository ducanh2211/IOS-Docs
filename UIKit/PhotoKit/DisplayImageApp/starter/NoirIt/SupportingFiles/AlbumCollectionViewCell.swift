
import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
  static let reuseIdentifier = "albumCell"
  @IBOutlet weak var emptyView: UIImageView!
  @IBOutlet weak var photoView: UIImageView!
  @IBOutlet weak var albumTitle: UILabel!
  @IBOutlet weak var albumCount: UILabel!

  override func prepareForReuse() {
    super.prepareForReuse()
    albumTitle.text = "Untitled"
    albumCount.text = "0 photos"
    photoView.image = nil
    photoView.isHidden = true
    emptyView.isHidden = false
  }

  func update(title: String?, count: Int) {
    albumTitle.text = title ?? "Untitled"
    albumCount.text = "\(count.description) \(count == 1 ? "photo" : "photos")"
  }
}
