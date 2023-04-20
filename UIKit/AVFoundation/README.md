# AVFoundation

Là framework dùng để làm việc với audio và video trên IOS.

## Capture 

Theo Apple Documents: 
`AVFoundation Capture` là một sub-system cung cấp high-level API để thao tác với video, audio, photo. Dùng với mục đích: 
- Build custom camera UI.
- Cung cấp cho user nhiều quyền kiểm soát output (photo, video) hơn như: focus, exposure, stabilization.
- Cung cấp output ở định dạng khác so với system Camera như: RAW format photos, depth maps, videos với custom timed metadata.
- Có quyền truy cập trực tiếp vào pixel hoặc audio data streaming từ thiết bị đầu vào (camera sau của iphone,...).

>>> Note
Nếu như chỉ muốn dùng system Camera UI để chụp ảnh hoặc quay video thì nên sử dụng `UIImagePickerController`.  

![](Images/Screen Shot 2023-04-20 (1))

Các thành phần chính:
- Session (AVCaptureSession): là thành phần cốt lõi, nó sẽ điều khiển flow của media capture. Nó nhận vào input, xử lý data và xuất ra ouput.
- Input: là 1 object thuộc subclass của `AVCaptureInput`, thường là `AVCaptureDeviceInput` (có thể là camera sau và trước, micro).
- Output: là 1 object thuộc subclass của `AVCaptureOutput`, có thể là `AVCapturePhotoOutput` dùng để xử lý image, `AVCaptureVideoDataOutput` hoặc `AVCaptureMovieFileOutput` dùng dể xử lý video, audio.
- Ngoài ra còn có Capture Device, dùng để truy cập đến physical device (camera, mic của iphone) và dùng nó để tạo ra input. 
 
Sau đây là những bước cần thiết để setup custom Camera để chụp ảnh (record video thì khó vl nên để sau này bổ sung thêm =)))
 
```swift
class ViewController1: UIViewController {

  var captureSession: AVCaptureSession?
  var frontCamera: AVCaptureDevice?
  var backCamera: AVCaptureDevice?
  var frontCameraInput: AVCaptureDeviceInput?
  var backCameraInput: AVCaptureDeviceInput?
  var photoOutput: AVCapturePhotoOutput?
  var previewLayer: AVCaptureVideoPreviewLayer?
  var flashMode = AVCaptureDevice.FlashMode.off
  var currentCameraPosition: CameraPosition?
  var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
  
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

![](Images/Screen Shot 2023-04-20 (2))

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

>>> Important
Gọi `beginConfiguration()` trước khi thay đổi input hay output của session, và gọi `commitConfiguration()` sau khi đã thay đổi.

### Bước 3: 



### Reference:
- [Making a custom Camera](https://medium.com/@barbulescualex/making-a-custom-camera-in-ios-ea44e3087563)
- [Building a fullscreen camera app](https://www.appcoda.com/avfoundation-swift-guide/)
- [AVFoundation Apple Documents](https://developer.apple.com/documentation/avfoundation/capture_setup)
