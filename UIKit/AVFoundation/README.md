# AVFoundation

Là framework dùng để làm việc với audio và video trên IOS.

# I. Custom Camera

Theo Apple Documents: 
`AVFoundation Capture` là một sub-system cung cấp high-level API để thao tác với video, audio, photo. Dùng với mục đích: 
- Build custom camera UI.
- Cung cấp cho user nhiều quyền kiểm soát output (photo, video) hơn như: focus, exposure, stabilization.
- Cung cấp output ở định dạng khác so với system Camera như: RAW format photos, depth maps, videos với custom timed metadata.
- Có quyền truy cập trực tiếp vào pixel hoặc audio data streaming từ thiết bị đầu vào (camera sau của iphone,...).

> Note:
Nếu như chỉ muốn dùng system Camera UI để chụp ảnh hoặc quay video thì nên sử dụng `UIImagePickerController`.  

![](Images/Screen-Shot-2023-04-20-1.png)

Các thành phần chính:
- Session (AVCaptureSession): là thành phần cốt lõi, nó sẽ điều khiển flow của media capture. Nó nhận vào input, xử lý data và xuất ra ouput.
- Input: là 1 object thuộc subclass của `AVCaptureInput`, thường là `AVCaptureDeviceInput` (có thể là camera sau và trước, micro).
- Output: là 1 object thuộc subclass của `AVCaptureOutput`, có thể là `AVCapturePhotoOutput` dùng để xử lý image, `AVCaptureVideoDataOutput` hoặc `AVCaptureMovieFileOutput` dùng dể xử lý video, audio.
- Ngoài ra còn có Capture Device, dùng để truy cập đến physical device (camera, mic của iphone) và dùng nó để tạo ra input. 
 
Sau đây là những bước cần thiết để setup custom Camera để chụp ảnh (record video thì khó vl nên để sau này bổ sung thêm =)))
 
```swift
class ViewController: UIViewController {

  var captureSession: AVCaptureSession?
  var frontCamera: AVCaptureDevice?
  var backCamera: AVCaptureDevice?
  var frontCameraInput: AVCaptureDeviceInput?
  var backCameraInput: AVCaptureDeviceInput?
  var photoOutput: AVCapturePhotoOutput?
  var previewLayer: AVCaptureVideoPreviewLayer?
  var flashMode = AVCaptureDevice.FlashMode.off
  var currentCameraPosition: CameraPosition?
  var capturedPhoto: UIImage?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    checkAuthorization()
  }
  
  ...
  
  enum CameraPosition {
    case front
    case back
  }
  
}
```
 
### Bước 1: Authorization

Trước khi muốn truy cập vào camera trên thiết bị của user thì cần phải được user xác nhận cho phép:
- Cần phải thêm key `NSCameraUsageDescription` vào file `Info.plist`   

![](Images/Screen-Shot-2023-04-20-2.png)

- Check xem app đã được authorized chưa, nếu chưa thì request 

```swift
func checkAuthorization() {
  switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      self.requestAuthorization()
    case .authorized:
      self.setupAndStartCaptureSession()
    case .restricted, .denied:
      break
    @unknown default:
      break
  }
}

func requestAuthorization() {
  AVCaptureDevice.requestAccess(for: .video) { granted in
    if granted {
      DispatchQueue.main.async {
        self.setupAndStartCaptureSession()
      }
    }
  }
}
```

> Note: completionHandler của method `requestAccess(for:completionHandler:)` được gọi trên 1 thread ngẫu nhiên do system quyết định. Nên nếu setup UI thì cần phải dispatch về main queue.

### Bước 2: Create và config `AVCaptureSession`

Để create và config `Capture Session` sẽ cần qua các bước:
1. Khởi tạo 1 session mới
2. Tìm kiếm và config những capture devices phù hợp
3. Tạo inputs từ capture device, kết nối tới session
4. Tạo và config ouput, kết nối tới session
5. Start session

```swift
func setupAndStartCaptureSession() {
  // Khởi tạo background concurrent queue
  let sessionQueue = DispatchQueue(label: "concurrent.session.queue")
  
  sessionQueue.async {
    // Khởi tạo 1 capture session mới
    self.captureSession = AVCaptureSession()
    
    // Config preset của session
    if self.captureSession.canSetSessionPreset(AVCaptureSession.Preset.photo) {
      self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    // Kết nối input
    
    // Kết nối output
    
    // Start session
    self.captureSession.startRunning()
  }
}
```

Giải thích:
- Tại sao lại phải khởi tạo background queue? Vì `captureSession.startRunning()` sẽ bắt đầu flow của session và nó sẽ block thread hiện tại cho đến khi hoàn thành hoặc throw error. Do đó, cần start session ở queue khác main.
- Property `sessionPreset` sẽ quyết định chất lượng và độ phân giải của media (image, video, audio). Do đó việc set preset sẽ giúp tối ưu performance cũng như dung lượng lưu trữ. Note: `AVCaptureSession.Preset.photo` dùng cho high-quality image, nếu như cố tình record video sẽ dẫn đến lỗi, do đó có thể `preset` khác phù hợp cho cả photo và video.

> Important:
Gọi `beginConfiguration()` trước khi thay đổi input hay output của session, và gọi `commitConfiguration()` sau khi đã thay đổi.

### Bước 3: Setup Input

Đầu tiên để setup input thì cần phải setup device.

```swift
func setupInputs() {
  // Setup device
  // 1
  let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                          mediaType: AVMediaType.video,
                                                          position: AVCaptureDevice.Position.unspecified)
  let devices = discoverySession.devices
  
  // 2
  for device in devices {
    if device.position == .back {
      self.backCamera = device
    }
    else if device.position == .front {
      self.frontCamera = device
    }
  }
  
  // Setup inputs
  // 3
  if let backCamera = self.backCamera {
  // 4
    self.backCameraInput = try? AVCaptureDeviceInput(device: backCamera)
    
    if let backCameraInput = self.backCameraInput, self.captureSession.canAddInput(backCameraInput) {
      // 5
      self.backCameraInput = backCameraInput
      self.captureSession.addInput(backCameraInput)
      self.currentCameraPosition = .back
    }
  }
  
  // 6
  else if let frontCamera = self.frontCamera {
    self.frontCameraInput = try? AVCaptureDeviceInput(device: frontCamera)
    
    if let frontCameraInput = self.frontCameraInput, self.captureSession.canAddInput(frontCameraInput) {
      self.frontCameraInput = frontCameraInput
      self.captureSession.addInput(frontCameraInput)
      self.currentCameraPosition = .front
    }
  }    
}
```

Giải thích:
1. Tìm những device phù hợp cho media type `video` (bao gồm cả image).
Init từ `DiscoverySession(deviceTypes:mediaType:position:)` sẽ return lại tất cả device phù hợp (`positon`bao gồm cả front và back camera, nhiều `deviceType` khác nhau).
Ngược với nó `default(_:for:position:)` chỉ return lại 1 device phù hợp duy nhất. 
2. Lặp qua tất cả các device phù hợp và xác định cái nào là front, cái nào là back camera.
3. Config `backCameraInput` nếu có `backCamera` 
4. Khởi tạo input từ device cụ thể `backCamera`.
5. Check xem `captureSession` có thể add được input không, nếu được thì kết nối input với session.
6. Vì session chỉ cho phép 1 input (dựa theo loại camera, front hoặc back) trong 1 thời điểm. Nên nếu back camera phù hợp thì sẽ sử dụng input từ back camera còn không sẽ sự dụng front camera để lấy input. 

### Bước 4: Setup Output

Có nhiều loại output khác nhau. Ví dụ:
- AVCapturePhotoOutput: dùng để capture ouput cho still photo, live photos
- AVCaptureMovieFileOutput: dùng để capture output cho records video và audio để lưu vào file QuickTime.
- AVCaptureVideoDataOutput: dùng để capture output cho records video và cung cấp quyền truy cập và xử lý từng frame của video dưới dạng data. 

```swift
func setupOutputs() {
  self.photoOutput = AVCapturePhotoOutput()
  if self.captureSession.canAddOutput(self.photoOutput) {
    self.captureSession.addOutput(self.photoOutput)
  }
}
```

### Bước 5: Tạo PreviewLayer

Sau 4 bước trên chúng ta đã có input, output và session. Bây giờ điều cần làm là làm sao để hiển thị hình ảnh từ camera lên màn hình điện thoại. Để làm được điều này chúng ta sẽ thao tác với class `AVCaptureVideoPreviewLayer` (subclass của CALayer).

```swift
func setupPreviewLayer() {
  self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
  self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
  view.layer.insertSublayer(previewLayer, at: 0)
  self.previewLayer.frame = view.frame
}
``` 

### Bước 6: Chụp ảnh

```swift
@objc func capturePhoto() {
  let settings = AVCapturePhotoSettings()
  settings.flashMode = self.flashMode
  self.photoOutput.capturePhoto(with: settings, delegate: self)
}

extension ViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else { return }
    self.capturedPhoto = image
  }
}
```
Kết hợp các bước trên chúng ta sẽ có func `setupAndStartCaptureSession`

```swift
func setupAndStartCaptureSession() {
  // Khởi tạo background concurrent queue
  let sessionQueue = DispatchQueue(label: "concurrent.session.queue")
  
  sessionQueue.async {
    // Khởi tạo 1 capture session mới
    self.captureSession = AVCaptureSession()
    
    // Config preset của session
    if self.captureSession.canSetSessionPreset(AVCaptureSession.Preset.photo) {
      self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    // Kết nối input
    self.setupInputs()
    
    // Kết nối output
    self.setupOutputs()
    
    // Setup preview layer
    DispatchQueue.main.async {
      self.setupPreviewLayer()
    }
    
    // Start session
    self.captureSession.startRunning()
  }
}
```

### Chuyển đổi camera

```swift
@objc func switchCameraPosition() {
  self.captureSession.beginConfiguration()
  
  guard let currentCameraPosition = currentCameraPosition else { return }
  
  switch currentCameraPosition {
    case .front:
      if let backCameraInput = backCameraInput, let frontCameraInput = frontCameraInput {
        self.captureSession.removeInput(frontCameraInput)
        self.captureSession.addInput(backCameraInput)
        self.currentCameraPosition = .back
      }
    case .back:
      if let backCameraInput = backCameraInput, let frontCameraInput = frontCameraInput {
        self.captureSession.removeInput(backCameraInput)
        self.captureSession.addInput(frontCameraInput)
        self.currentCameraPosition = .front
      }
  }
  
  self.captureSession.commitConfiguration()
}
```

Giải thích:
- Để thay đổi camera thì chúng ta cần remove `camera input` cũ và add `camera input` mới.
- Nhớ đặt đoạn code thay đổi input giữa `beginConfiguration()` và `commitConfiguration()`

# Reference:
1. [Making a custom Camera](https://medium.com/@barbulescualex/making-a-custom-camera-in-ios-ea44e3087563)
2. [Building a fullscreen camera app](https://www.appcoda.com/avfoundation-swift-guide/)
3. [AVFoundation Apple Documents](https://developer.apple.com/documentation/avfoundation/capture_setup)

# II. Play Video

![](images/about-AVFoudation.png)

Để xử lý video chúng ta sẽ cần tìm hiểu về các class sau:
- AVPlayerLayer: là subclass của `CALayer`, nó dùng để phát playback của `AVPlayer` object.
- AVAsset: là object chứa các thông tin tĩnh của asset, ví dụ như thời lượng video, ngày khởi tạo.
- AVPlayerItem: là object chứa thông tin động của asset, nó đại diện cho trạng thái hiện tại của video được phát.

## **1. AVAsset**

### **1.1. Tổng quan**

- `AVAsset` là tập hợp của các data khác nhau, bao gồm: audio tracks, videos tracks, title, length, video size. Nó support hầu hết các media file format.

- `AVAsset` có thể chứa 1 hoặc nhiều `AVAssetTrack`. `AVAssetTrack` có `mediaType` property xác định type của track như video tracks, audio tracks, subtitle tracks, text tracks...

Ví dụ: 1 AVAsset (video) lấy từ Library chứa video track và audio track.

### **1.2. Tạo AVAsset**

AVAsset là một abstract class. Khi khởi tạo, một instance thuộc kiểu AVURLAsset sẽ được khởi tạo từ URL chứ không phải instance của AVAsset.

```swift
init (url URL : URL , options: [ String : Any ]? = nil )
```

Options có thể bao gồm key và value như sau:
- AVURLAssetPreferPreciseDurationAndTimingKey: It has a boolean value wrapped in NSNumber as a value, and determines whether random access is enabled with an accurate duration and time when the asset is ready. The default value is false, but if set to true, preparing an asset takes a little longer than usual, so it is recommended to use it only when manipulating an asset.
- AVURLAssetReferenceRestrictionsKey: It has an enumerated value of wrapped in NSNumber AVAssetReferenceRestrictionsas value, and by combining these values, the use of external media data is limited.
- AVURLAssetHTTPCookiesKey: It has a value of a cookie sent when an HTTP request is made.
- AVURLAssetAllowsCellularAccessKey: A key that has a boolean value of whether to use the cellular network when viewing media data. The default value is true.


## **2. Playing media**

![](images/avplayer-core.png)

### **2.1. AVPlayer**

Là central cotroller class dùng để phát media asset và kiểm soát thời gian. Nó có thể phát media local và streaming.

> Note: `AVPlayer` chỉ cho phép phát 1 media duy nhất. Nếu muốn phát media liên tiếp thì phải dùng tới subclass `AVQueuePlayer`.

`AVPlayer` có những property và method dùng để control video như:

- `rate: Float`: the current playback rate. Zero means to pause, 1 means the video plays at regular speed, 2 means double-speed, and etc. Setting rate to a negative number instructs playback to begin at that number times regular speed in reverse.
- `status: AVPlayer.Status`: a status that indicates whether the player can be used for playback.
- `currentItem: AVPlayerItem?`: the player’s current player item.
- `func play()`: begins playback of the current item.
- `func pause()`: pauses playback of the current item.
- `func seek(to: CMTime)`: sets the current playback time to the specified time.
- `func currentTime() -> CMTime`: returns the current time of the current player item.
- `func replaceCurrentItem(with: AVPlayerItem?)`: replaces the current player item with a new player item.

### **2.2. AVPlayerItem**

Bởi vì `AVAsset` chỉ chứa những thuộc tính static của media, nên không phù hợp để playback media với `AVPlayer`. Thay vào đó, cần sử dụng tính dynamic của `AVPlayerItem`. Class này sẽ chỉ ra state của playback của một asset được sử dụng bởi `AVPlayer`. `AVPlayerItem` chứa những property và method dùng để lấy được: time zone, screen size, thời gian phát hiện tại,...

Những property thông dụng:
- `asset: AVAsset`: the asset provided during initialization.
- `duration: CMTime`: the duration of the item.
- `status: AVPlayerItem.Status`: the status of the player item.
- `forwardPlaybackEndTime: CMTime`: the time at which forward playback ends.
- `reversePlaybackEndTime: CMTime`: the time at which reverse playback ends.

### **2.3. AVKit và AVPlayerLayer**

Do `AVPlayer` và `AVPlayerItem` là các object không hiển thị trên màn hình, vì vậy cần phải sử dụng tới class khác để giúp chúng hiển thị media lên screen:

- `AVKit`: cách đơn giản nhất dùng để hiện thị nội dung của video là sử dụng class `AVPlayerViewController` trong `AVKit` framework. Nó sẽ cung cấp các method dùng để quản lý và điều khiển playback.

- `AVPlayerLayer`: nếu như bạn muốn custom player thì cần phải custom `AVPlayerLayer` (subclass của `CALayer`). Lớp layer này có thể được add như là sublayer của 1 view dùng để hiển thị nội dung video. Tuy nhiên, layer này chỉ có chức năng hiển thị, việc quản lý và điều khiển những tính năng playback (dừng, phát, tua,...) phải tự implement.

### **2.4. Tổng kết**

Để chạy playback chúng ta cần khởi tạo và config các class sau:
- Khởi tạo AVAsset.
- Khởi tạo AVPlayerItem từ .init(asset:) hoặc .init(url:) 
- Khởi tạo AVPlayer từ .init(), và gọi method `replaceCurrentItem(_:)` để gán 1 item mới cho player.
- Khởi tạo AVPlayerLayer từ .init(player:), gán `frame` cho layer và config `videoGravity`, add sublayer vào view để display content.

### **2.5. Observering playback state**

Vì `AVPlayers` và `AVPlayerItems` là các dynamic objects nên state của nó luôn luôn thay đổi. Nếu bạn muốn phản ứng và xử lý trước những thay đổi này thì cần sử dụng tới KVO (Key-value Observing). Với KVO, bạn có thể theo dõi sự thay đổi của state của player và item từ đó đưa ra hướng xử lý.

Một trong những property thông dụng nhất của `AVPlayerItem` là `status`. Nó thường được sử dụng để xác định xem `AVPlayerItem` có thể play không.

Here's Apple's example code.

```swift
let url: URL = // Asset URL
 
var asset: AVAsset!
var player: AVPlayer!
var playerItem: AVPlayerItem!
 
// Key-value observing context
private var playerItemContext = 0
 
let requiredAssetKeys = [
    "playable",
    "hasProtectedContent"
]
 
func prepareToPlay() {
    // Create the asset to play
    asset = AVAsset(url: url)
 
    // Create a new AVPlayerItem with the asset and an
    // array of asset keys to be automatically loaded
    playerItem = AVPlayerItem(asset: asset,
                              automaticallyLoadedAssetKeys: requiredAssetKeys)
 
    // Register as an observer of the player item's status property
    playerItem.addObserver(self,
                           forKeyPath: #keyPath(AVPlayerItem.status),
                           options: [.old, .new],
                           context: &playerItemContext)
 
    // Associate the player item with the player
    player = AVPlayer(playerItem: playerItem)
}
```

Truy cập và xử lý thay đổi của `status` bằng cách override method `observeValue(forKeyPath:of:change:context:)`

```swift
override func observeValue(forKeyPath keyPath: String?,
                           of object: Any?,
                           change: [NSKeyValueChangeKey : Any]?,
                           context: UnsafeMutableRawPointer?) {
 
    // Only handle observations for the playerItemContext
    guard context == &playerItemContext else {
        super.observeValue(forKeyPath: keyPath,
                           of: object,
                           change: change,
                           context: context)
        return
    }
 
    if keyPath == #keyPath(AVPlayerItem.status) {
        let status: AVPlayerItemStatus
        if let statusNumber = change?[.newKey] as? NSNumber {
            status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
        } else {
            status = .unknown
        }
        // Switch over status value
        switch status {
        case .readyToPlay:
            // Player item is ready to play.
        case .failed:
            // Player item failed. See error.
        case .unknown:
            // Player item is not yet ready.
        }
    }
}
```

### **2.6. Observering playback time**

#### **2.6.1. CMTime**

Media playback là hoạt động dựa trên thời gian (time-based activity). Rất nhiều core functions của `AVPlayers` và `AVPlayerItems` liên quan đến control timing của media. Do đó `AVFoundation` sử dụng 1 kiểu dữ liệu riêng `CMTime` để quản lý time.

`CMTime` là kiểu dữ liệu thuộc `Core Media` framework, nó mô tả thời gian bằng cách chia nhỏ ra nhiều phần.

```swift
public struct CMTime {
    public var value: CMTimeValue
    public var timescale: CMTimeScale
    public var flags: CMTimeFlags
    public var epoch: CMTimeEpoch
}

// 0.25 seconds
let quarterSecond = CMTime(value: 1, timescale: 4)
 
// 10 second mark in a 44.1 kHz audio file
let tenSeconds = CMTime(value: 441000, timescale: 44100)
 
// 3 seconds into a 30fps video
let cursor = CMTime(value: 90, timescale: 30)
```

#### **2.6.2. Observing time**

Để quan sát thời gian một cách định kỳ (preodic timing), sử dụng method của `AVPlayer` `addPeriodicTimeObserver(forInterval:queue:using:)`. Nó có thể được sử dụng để update UI trong custom player.

Method này nhận 1 `CMTime` value đại diện cho time interval, 1 `serial queue` nơi callback được gọi, và 1 callback block được gọi lại sau mỗi 1 khoảng time interval.

```swift
var player: AVPlayer!
var playerItem: AVPlayerItem!
var timeObserverToken: Any?

func addPeriodicTimeObserver() {
    // Notify every half second
    let timeScale = CMTimeScale(NSEC_PER_SEC)
    let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

    timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) {
        [weak self] time in
        // update player transport UI
    }
}

func removePeriodicTimeObserver() {
    if let timeObserverToken = timeObserverToken {
        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
}
```

### **3. Custom video player**

# III. Edit Video

## **3.1. Export Video**

`AVAssetExportSession` cho phép export media asset như là videos, audio files sang format hoặc compression settings khác. Nó cho phép bạn custom các tham số khác nhau và thực hiện các task như transcoding, resizing và applying filters cho media.

Để có thể export media chúng ta sẽ thực hiện các bước sau:

- Tạo `outputURL: URL`: là url mà export session sẽ write đến.

- Tạo `timeRange: CMTimeRange`: là khoảng thời gian của media sẽ được export.

- Tạo `exportSession: AVAssetExportSession`: config export session để export instance của AVAsset bằng việc setting `export preset`, `output file type`, `output URL`.

- Export bằng method `exportAsynchronously(completionHandler:)`.

Những key aspects của `AVAssetExportSession`:
- **Initialization**: `init?(asset: AVAsset, presetName: String)`, `presetName` chỉ ra output format mong muốn. Những preset thông dụng như `AVAssetExportPresetLowQuality`, `AVAssetExportPresetMediumQuality`, `AVAssetExportPresetHighestQuality`.

- **Output Configuration**: The `outputURL` property specifies the file URL where the exported media will be saved. The `outputFileType` property defines the file format of the exported media. You can set it to a specific file type such as `.mov`, `.mp4`, `.m4a`, etc.

- **Export Settings**: The available export settings depend on the preset or custom configuration you choose. You can access the supported presets using the `exportPresetsCompatibleWithAsset(_:)` method. Additionally, you can modify properties such as `videoComposition`, `audioMix`, `metadata`, `timeRange`, `shouldOptimizeForNetworkUse`, etc., to apply specific transformations or modifications to the exported media.

- **Progress Tracking**: You can track the progress of the export using key-value observing (KVO) on the progress property of the `AVAssetExportSession`. This allows you to display a progress bar or update UI elements to indicate the export progress to the user.

- **Cancellation and Pausing**: You can cancel an ongoing export operation by calling the `cancelExport()` method on the `AVAssetExportSession`. Additionally, the `pause()` and `resume()` methods allow you to pause and resume the export process if needed.

```swift
  func trimmingVideo(asset: AVURLAsset, fileName: String, startTime: Float, endTime: Float) {
        let fileManager = FileManager.default
        let fileName = "Trimming_video_\(fileName).mp4"

        // Tạo outputURL
        guard let outputURL = createVideoEditorFolder()?.appendingPathExtension(fileName) else { return }

        // Xoá file tại outputURL
        _ = try? fileManager.removeItem(at: outputURL)

        // Tạo time range
        let start: CMTime = CMTime(seconds: Double(startTime), preferredTimescale: 1000)
        let end: CMTime = CMTime(seconds: Double(endTime), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: start, end: end)

        // Tạo và config exportSession
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.timeRange = timeRange

        // Export asynchronously media 
        exportSession.exportAsynchronously {
            switch exportSession.status {
                case .completed:
                    // Export thành công
                    print("exported success")
                case .failed:
                    // Export thất bại
                    print("failed \(String(describing: exportSession.error))")
                case .cancelled:
                    // Export bị cancel
                    print("cancel \(String(describing: exportSession.error))")
                default:
                    break
            }
        }
    }

    func createVideoEditorFolder() -> URL? {
        let fileManager = FileManager.default
        let rootFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let nestedFolderURL = rootFolderURL.appendingPathComponent("videoEditor")

        if !fileManager.fileExists(atPath: nestedFolderURL.path) {
            do {
                try fileManager.createDirectory(at: nestedFolderURL, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }
        return nestedFolderURL
    }
```

## **3.2. Generate thumbnail**

`AVAssetImageGenerator` cho phép tạo ra ảnh tĩnh từ media assets như video hoặc audio. Nó cung cấp phương thức đơn giản để trích xuất frames từ asset trong 1 thời điểm cụ thể hoặc trong các khoảng thời gian đều đặn.

Synchronously generate thumbnail

```swift
func generateThumbnail(path: URL) -> UIImage? {
    do {
        let asset = AVURLAsset(url: path, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
        let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
```

Asynchronously generate thumbnail

```swift
func generateThumbnail(path: URL, identifier: String,
                       completion: @escaping (_ thumbnail: UIImage?, _ identifier: String) -> Void) {

      let asset = AVURLAsset(url: path, options: nil)
      let imgGenerator = AVAssetImageGenerator(asset: asset)
      imgGenerator.appliesPreferredTrackTransform = true

      imgGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _,image, _, _, _ in
          if let image = image {
              DispatchQueue.main.async {
                  completion(UIImage(cgImage: image), identifier)
              }
          }
      }
    }
```

## **3.3. Merge video**

Để có thể merge được videos trước tiên chúng ta cần tìm hiểu tổng quan về các class sau:
- AVComposition/AVMutableComposition
- AVMutableCompositionTrack 
- AVAssetExportSession

![](images/AVMutableComposition-overview.awebp)

### **6.1. AVComposition/AVMutableComposition**

`AVComposition` là subclass của `AVAsset`, nó có chứa nhiều track là instance của `AVCompositionTrack` (subclass của `AVAssetTrack`). Cho phép kết hợp và xử lý media từ nhiều asset khác nhau tạo thành 1 composition asset.

`AVComposition` là immutable do đó chúng ta cần sử dụng `AVMutableComposition` để có thể thêm, xoá, chỉnh sửa các track trong composition asset. 

### **6.2. Merge video**

Tổng quan các bước:
- Tạo 1 instance `AVMutableComposition` để chứa các track.
- Tạo và thêm 2 track rỗng `AVMutableCompositionTrack` vào `AVMutableComposition`, 1 track chứa `mediaType` là audio và 1 track chứa `mediaType` là video.
- Lấy ra 2 source track `AVAssetTrack` từ `AVAsset` thuộc kiểu video và audio.
- Insert time range từ source track vào composition track.
- Tạo instance của `AVAssetExportSession` để có thể export media.

```swift
func mergeVideos(videoAssets: [AVURLAsset], outcome: @escaping (Result<URL, Error>) -> Void) {
        // Tạo mutable composition
        let mixComposition = AVMutableComposition()

        // Tạo 2 composition track rỗng chứa video track và audio track
        guard let videoTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio,
                                                              preferredTrackID: kCMPersistentTrackID_Invalid)
        else { return }

        var insertTime: CMTime = .zero

        // Insert time range cho video track và audio track từ source track
        for sourceAsset in videoAssets {
            guard let videoAssetTrack = sourceAsset.tracks(withMediaType: .video).first,
                  let audioAssetTrack = sourceAsset.tracks(withMediaType: .audio).first
            else { return }

            do {
                let timeRange = CMTimeRange(start: .zero, duration: sourceAsset.duration)
                try videoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: insertTime)
                try audioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: insertTime)
                videoTrack.preferredTransform = videoAssetTrack.preferredTransform
            } catch {
                DispatchQueue.main.async {
                    outcome(.failure(error))
                }
            }

            insertTime = CMTimeAdd(insertTime, sourceAsset.duration)
        }

        // Tạo export session
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathExtension("merge_movies.mp4")

        guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Export media
        exportSession.exportAsynchronously {
            switch exportSession.status {
                case .failed:
                    if let error = exportSession.error {
                        DispatchQueue.main.async {
                            outcome(.failure(error))
                        }
                    }
                case .cancelled:
                    if let error = exportSession.error {
                        DispatchQueue.main.async {
                            outcome(.failure(error))
                        }
                    }
                default:
                    DispatchQueue.main.async {
                        outcome(.success(outputURL))
                    }
            }
        }
    }
```

#### Adjust orientation

- UIImage.Orientation

Sau các bước trên, ta đã có thể export 1 video hoàn chỉnh từ nhiều video khác nhau. Tuy nhiên các video lại có orientation (UIImage.Orientation) khác nhau. Hay nói đơn giản hơn, 1 video có thể được record theo chiều dọc, chiều ngang, chiều dọc thì có xuôi ngược, ngang thì có trái, phải ([đọc bài này để biết thêm chi tiết](https://eorvain-app.medium.com/image-orientation-on-ios-abaf8321820b)).

Theo [Apple documentation](https://developer.apple.com/documentation/uikit/uiimage/orientation#):

"Orientation values are commonly found in image metadata, and specifying image orientation correctly can be important both for displaying the image and for certain kinds of image processing.

The UIImage class automatically handles the transform necessary to present an image in the correct display orientation according to its orientation metadata, so an image object's imageOrientation property simply indicates which transform was applied.

For example, an iOS device camera always encodes pixel data in the camera sensor's native landscape orientation, along with metadata indicating the camera orientation. When UIImage loads a photo shot in portrait orientation, it automatically applies a 90° rotation before displaying the image data, and the image's imageOrientation value of UIImage.Orientation.right indicates that this rotation has been applied.
"

Đoạn này không sure kèo: Tất cả những ảnh được capture từ camera sẽ được Apple lưu dưới dạng landspace left (tai thỏ nằm bên trái). Vì vậy, để image có thể hiện thị đúng, `UIImage` sẽ tự động apply 1 `transform`. `imageOrientation` chính là property để chỉ ra `transform` nào đã được apply.

Trong trường hợp `AVAssetTrack` thì property `preferredTransform` sẽ chỉ ra orientation của asset.

- VD:
  - `preferredTransform = CGAffineTransform(a: 1, b: 0, c: 1, d: 0, tx: 0, ty: 0)` (tương đương `identity`) thì asset sẽ là landscape left, orientation là up. Tức là asset không cần apply tranform vì bản thân nó đã đúng ngay từ đầu.
  - `preferredTransform = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: 0)`. Tương đương, asset là portrait, orientation là left. Tức là, asset cần phải quay 90• sang trái để display chuẩn.


- Giờ chúng ta sẽ chỉnh orientation của video đầu ra sao cho chuẩn:

```swift
Struct VideoHelper {

  static func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
      
      var assetOrientation: UIImage.Orientation = .up
      var isPortrait: Bool = false

      switch (transform.a, transform.b, transform.c, transform.d) {
            case (1, 0, 0, 1):
                assetOrientation = .up
            case (-1, 0, 0, -1):
                assetOrientation = .down
            case (0, -1, 1, 0):
                assetOrientation = .left
                isPortrait = true
            case (0, 1, -1, 0):
                assetOrientation = .right
                isPortrait = true
            default:
                break
        }
      return (assetOrientation, isPortrait)
  }

  static func makeVideoCompositionInstruction(_ videoTrack: AVAssetTrack,
                                              asset: AVAsset,
                                              renderSize: CGSize,
                                              startTime: CMTime,
                                              endTime: CMTime) ->AVMutableVideoCompositionLayerInstruction {

        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        let assetTrack = asset.tracks(withMediaType: .video)[0]
        let preferredTransform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(preferredTransform)
        var scaleToFitAspect: CGFloat = 1

        if assetInfo.isPortrait {
            // `naturalSize` lúc này sẽ bị đảo ngược thành (1920, 1080) giống như landspace,
            // do đó để sử dụng như portrait cần phải đổi giá trị height và width của `naturalSize`
            scaleToFitAspect = renderSize.height / assetTrack.naturalSize.width
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitAspect, y: scaleToFitAspect)
            let posX = renderSize.width/2 - (assetTrack.naturalSize.height * scaleToFitAspect)/2
            let posY = renderSize.height/2 - (assetTrack.naturalSize.width * scaleToFitAspect)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)

            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor), at: .zero)

      } else {
          scaleToFitAspect = renderSize.width / assetTrack.naturalSize.width
          let scaleFactor = CGAffineTransform(scaleX: scaleToFitAspect, y: scaleToFitAspect)
          let posX = (renderSize.width - assetTrack.naturalSize.width * scaleToFitAspect) / 2
          let posY = (renderSize.height - assetTrack.naturalSize.height * scaleToFitAspect) / 2
          let moveFactor = CGAffineTransform(translationX: posX, y: posY)
          
          instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor)concatenating(moveFactor), at: .zero)
      }

      instruction.setOpacity(1, at: startTime)
      instruction.setOpacity(0, at: endTime)
      return instruction
  }

}
```

Giải thích:

- `orientationFromTransform(_:)` giúp ta chỉ ra orientation và portrait hay landscape.
- `makeVideoCompositionInstruction(_:asset:renderSize:startTime:endTime:)`: 
  - `AVMutableVideoCompositionLayerInstruction`: là class được associate with 1 video track trong 1 composition. Nó được dùng để transform layer từ đó giúp cho việc hiển thị video theo chiều mong muốn.


## 3.4. Create movies from still image and audio

### 3.4.1. Frame buffer

`Frame buffer` là một vùng nhớ đặc biệt dùng lưu trữ pixel data (dữ liệu điểm ảnh) để tạo nên 1 frame của ảnh hoặc video. `Frame buffer` là nơi ta theo dõi toàn bộ điểm ảnh ta vẽ. Mỗi điểm ảnh sẽ có information riêng chứa color, intensity. Mỗi khi ta thêm hoặc update pixel, ta cũng update `frame buffer`.

Tương tự với video, mỗi frame của video được hình thành từ vô số các pixels. `frame buffer` cũng sẽ lưu pixel data cho mỗi frame. Mỗi khi video được played, `frame buffer` sẽ liên tục update new frames.

`Frame buffer` hoạt động như 1 cầu nối giữa computer và các thiết bị hiển thị như màn hình. Là nơi chứa các thông tin cho việc hiển thị ở màn hình. Computer có thể thực thi các hành động như read hoặc write để hiển thị ra màn hình.

Nói tóm lại, 1 frame buffer của 1 image sẽ giữ tất cả các thông tin của pixels image đó. Còn với video, nó cũng có 1 frame buffer để hiển thị nội dung của frame hiện tại của video, khi video chạy, frame buffer sẽ cập nhập lại các pixel để hiển thị lên cho đúng.

### 3.4.2. Nội dung chính

Thông thường khi sử dụng `AVFoundation` để tạo video files thì dùng `AVAsset` và `AVAssetTrack`. Bạn có thể kết hợp một vài tracks và asset để tạo 1 video file. Các tracks phải chứa media data và duration. Still image files thì không có duration. Đây là vấn đề lớn nhất khi bạn muốn tạo video từ still image.

Chúng ta có thể sử dụng `CADisplayLink`, `AVPlayerItemVideoOutput` hoặc `AVCaptureDevice` để tạo ra frame buffers và lưu lại. Tuy nhiên trong trường hợp này chúng ta sẽ tạo ra `frame buffers` 1 cách thủ công từ `UIImage`, bằng cách sử dụng `AVAssetWriter` để convert `frame buffers` thành video file.


> Note (1 vài chú ý trước khi tạo video file)
>
> - What frame to use? Bởi vì image là ảnh tĩnh nên có thể sử dụng low frame rate để tạo ra video có size nhỏ hơn. Tuy nhiên, điều này có thể sinh ra lỗi nếu video đó được chèn vào cùng 1 video thông thường (có frame rate là 30, 60 fps hoặc cao hơn rất nhiều).
> - What dimensions will the final video have? Nó sẽ dễ dàng hơn nếu như chúng ta resize image và thêm padding bằng cách sử dụng `CoreImage` hoặc phần mềm edit khác trước khi nó trở thành video. Qua quá trình chuyển đổi sang video, `AVFoundation` có thể sẽ resize hoặc crop image nếu như input dimensions và output dimensions không khớp nhau.

#### **Writing Buffers using `AVAssetWriter`**

`AVAssetWriter` dùng để encode (mã hóa) media thành 1 file trên disk. `AVAssetWriter` hỗ trợ nhiều input khác nhau như audio, video, metadata (nó có property `inputs: [AVAssetWriterInput]`). Có thể tưởng tượng nó gần tương đồng với thằng `AVAssetExportSession`. Sự khác biệt là `AVAssetWriter` sử dụng nhiều input khác nhau, mỗi input là 1 single track, trong khi `AVAssetExportSession` chỉ sử dụng duy nhất 1 input là `AVAsset`. Kết quả cuối cùng của cả 2 là 1 video file.

Như đã đề cập ở trên, các bước cần chuẩn bị bao gồm:

1. Tạo 1 pixel buffer chứa chính xác thông tin về color space, size của image.
2. Render image thành pixcel buffer.
3. Tạo `AVAssetWriter` với 1 video input duy nhất.
4. Quyết định xem cần bao nhiêu frames trong khoảng thời lượng (duration) của video.
5. Tạo 1 vòng lặp, lặp qua hết total frames, mỗi vòng thì đều append pixel buffer
6. Dọn dẹp hết (clean up).

#### **Create `Pixel buffer`**

```swift
//create a CIImage
guard var staticImage = CIImage(image: image) else {
    throw ConstructionError.invalidImage //this is an error type I made up
}

//create a variable to hold the pixelBuffer
var pixelBuffer: CVPixelBuffer?

//set some standard attributes
let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

//create the width and height of the buffer to match the image
let width:Int = Int(staticImage.extent.size.width)
let height:Int = Int(staticImage.extent.size.height)

//create a buffer (notice it uses an in/out parameter for tpixelBuffervariable)
CVPixelBufferCreate(kCFAllocatorDefault,
                    width,
                    height,
                    kCVPixelFormatType_32BGRA,
                    attrs,
                    &pixelBuffer)

//create a CIContext
let context = CIContext()

//use the context to render the image into the pixelBuffer
context.render(staticImage, to: pixelBuffer!)
```

Đoạn code trên tạo ra `CIImage` từ `UIImage`. Sau đó, tạo 1 pixcel buffer với kích thước tương đương image. Cuối cùng, sử dụng `CIContext` để render image vào pixel buffer.

Mặc dù chúng ta nghĩ rằng `CIImage` chỉ là 1 image, nhưng Apple chỉ rõ rằng nó không thực sự là 1 image. `CIImage` cần đến 1 context (`CIContext`) để có thể render. Sự thật là, `CIImage` giống như là 1 hướng dẫn để khởi tạo 1 image. 

> Note: Cũng có thể sử dụng `CGImage` và `CoreGraphics` để tạo pixel buffers.

#### **Configure `AVAssetWriter`**

Với buffer tạo từ bước 1, bạn có thể config `AVAssetWriter`. Nó sẽ nhận vào các parameters là 1 dictionary, dùng để xác định `dimensions` và `format of outputs`. 

`Output dimension` được coi là 1 trong các settings quan trọng nhất. Nếu như `output dimension` khớp với image gốc thì quá tuyệt vời vì video sẽ không bị biến dạng. Tuy nhiên, nếu output nhỏ hơn, nó sẽ nén (compress) image lại cho tới khi fit thì thôi. Nếu output lớn hơn, image sẽ được mở rộng (expand) cho đến khi width hoặc height khớp với output size. 

Ví dụ cho việc hiển thị image với size 640 x 480 với các output size khác nhau:

![](images/output-sizes)

Để có thể configure output cho `AVAssetWriter`, đầu tiên ta cần tạo 1 dictionary như dưới đây:

```swift
// settings thủ công
let assetWriterSettings = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey : 400, AVVideoHeightKey: 400] as [String : Any]

// Sử dụng preset của Apple
let settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings
```

Ở ví dụ trên, chúng ta config thông số: output size là `400x400`, được encoding theo kiểu `.h264`, chất lượng video là `1920x1080` (fullHD). Để tìm hiểu thêm các setting, truy cập [Apple documentation](https://developer.apple.com/documentation/avfoundation/avoutputsettingsassistant).

> Note: `h.264`, được biết tới là `MPEG-4 Part 10` hoặc `AVC` (Advanced Video Coding). Được sử dụng rộng rãi trong việc nén video. Nó rất hiệu quả trong việc encoding data, giảm size của video nhưng không làm giảm chất lượng hình ảnh quá nhiều.

#### **Write the pixel buffer to the video file**

```swift
//generate a file url to store the video (some_image.jpg -> some_image.mov)
guard let imageNameRoot = imageName.split(separator: ".").first, let outputMovieURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("\(imageNameRoot).mov") else {
  throw ConstructionError.invalidURL //an error i made up
}

//delete any old file
do {
  try FileManager.default.removeItem(at: outputMovieURL)
} catch {
  print("Could not remove file \(error.localizedDescription)")
}

//create an assetwriter instance
guard let assetwriter = try? AVAssetWriter(outputURL: outputMovieURL, fileType: .mov) else {
  abort()
}

//generate 1080p settings
let settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings

//create a single video input
let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settingsAssistant)

//create an adaptor for the pixel buffer
let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
//add the input to the asset writer
assetwriter.add(assetWriterInput)

//begin the session
assetwriter.startWriting()
assetwriter.startSession(atSourceTime: CMTime.zero)

//determine how many frames we need to generate
let framesPerSecond = 30
//duration is the number of seconds for the final video
let totalFrames = duration * framesPerSecond
var frameCount = 0
while frameCount < totalFrames {
  if assetWriterInput.isReadyForMoreMediaData {
    let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(framesPerSecond))
    //append the contents of the pixelBuffer at the correct time
    assetWriterAdaptor.append(pixelBuffer!, withPresentationTime: frameTime)
    frameCount+=1
  }
}

//close everything
assetWriterInput.markAsFinished()
assetwriter.finishWriting {
  pixelBuffer = nil
}
```
Với setting đã được config như trên, `asset writer` có thể loop qua và append content of `pixel buffer` để tạo nên từng frame của video. ***Cần chú ý rằng,*** trong đoạn code trên, AVFoundation có cơ chế riêng để bảo toàn data. Do đó, nó sẽ không overwrite 1 file vì vậy ta cần xoá file cũ trước khi tạo mới 1 `AVAssetWriter`. (Điều này cũng tương tự với `AVAssetExportSession`)

Sau khi kết nối toàn bộ đoạn code trên, chúng ta sẽ xuất ra được 1 file video dựa trên image, nhưng sẽ không có audio. Để thêm audio vào video thì xem lại mục trước.



# Reference
1. [Studying AVFoundation](https://wnstkdyu.github.io/2018/05/03/avfoundationprogrammingguide/?fbclid=IwAR0bBXOULVra_94buzwnImW4Wm3RgDO2z_moBWFAq34b8Kqh-tHqu6TqbYk#Performing-Time-Based-Operations)
2. [Custom video player in Swift](https://iostutorialjunction.com/2020/06/custom-video-player-in-swift-using-avplayer.html)
3. [How to play, record and merge video in IOS](https://www.kodeco.com/10857372-how-to-play-record-and-merge-videos-in-ios-and-swift)
4. [How to trim and crop video in Swift](https://img.ly/blog/trim-and-crop-video-in-swift/#trimmingthetimeofavideo)
5. [AVComposition Chinese version](https://www.codersrc.com/archives/11548.html)
6. [Merge video Chinese version](https://juejin.cn/post/6944946138152140808)
7. [How to Play, Record and Merge Videos in iOS and Swift KODECO](https://www.kodeco.com/10857372-how-to-play-record-and-merge-videos-in-ios-and-swift#toc-anchor-011)
8. [Merging video with original orientation](https://stackoverflow.com/questions/74458011/merging-video-with-original-orientation)