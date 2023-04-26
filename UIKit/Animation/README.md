# Animation

Để tạo animation cho `view` chúng ta có một vài cách sau:
- UIView: 
  - UIView.animate()
  - UIView.transition()
  - UIView.addKeyframe()
- UIViewPropertyAnimator
- CoreAnimation


## Type method với UIView

```swift
    // Method 1
    class func animate(withDuration duration: TimeInterval,
                       delay: TimeInterval,
                       options: UIView.AnimationOptions = [], 
                       animations: @escaping () -> Void,
                       completion: ((Bool) -> Void)? = nil)
    
    // Method 2
    class func animate(withDuration duration: TimeInterval,
                       delay: TimeInterval,
                       usingSpringWithDamping dampingRatio: CGFloat,
                       initialSpringVelocity velocity: CGFloat,
                       options: UIView.AnimationOptions = [],
                       animations: @escaping () -> Void,
                       completion: ((Bool) -> Void)? = nil)
```

#### Method 1:
 
- `duration`: khoảng thời gian chạy của animation.
- `delay`: khoảng thời gian delay trước khi animation thực sự bắt đầu.
- `options` xem enum `UIView.AnimationOptions`. 1 vài case thông dụng:
  - `.curveEaseIn`: xuất phát chậm sau đó tăng tốc dần dần.
  - `curveEaseOut`: xuất phát nhanh sau đó giảm tốc dần dần về cuối.
  - `.curveEaseInOut`: kết hợp của 2 case trên, xuất phát chậm, tăng tốc ở giữa và chậm dần ở cuối.
- `animations`: là 1 closure dùng để chứa những animation chúng ta muốn thực hiện.
- `completion`: là 1 closure nhận vào 1 boolean value xác định xem animation đã finished chưa, được gọi sau khi animation chạy xong.

Minh hoạ

```swift
UIView.animate(withDuration: 1.5,
                delay: 0.5,
                options: .curveEaseInOut,
                animations: {
  // 1
  self.redView.frame.size.width -= 50
  // 2
  self.redView.center.y += 200
  // 3
  self.redView.center.x = self.view.center.x
  // 4
  self.redView.alpha = 0.4
}, completion: { finished in
  // 5
  self.redView.backgroundColor = .systemBlue
})
```

Giải thích:
1. Giảm `width` của view đi 50 px
2. Tăng toạ độ `y` của view lên 200px -> di chuyển xuống dưới 200px 
3. Set `center.x` của view bằng `center.x` của superView -> view di chuyển xuống dưới nhưng vẫn giữ nguyên toạ độ trên trục x (không bị di chuyển lệch trái)
4. Giảm `alpha` xuống 0.4
5. Sau khi kết thúc `animation` thì chuyển `backgroundColor` sang blue.

![](Images/Simulator-Screen-Recording-1.gif)

> Note: 
> Thứ tự của code sẽ ảnh hưởng đến kết quả của animation. Nếu như trong Minh hoạ trên, nếu (3) xảy ra trước (1) thì coi như (3) sẽ không có tác dụng và khi đó view sẽ di chuyển lệch về bên trái (`center.x` bị thay đổi) 

#### Method 2: sử dụng thêm `spring`
                   

Minh hoạ

```swift
UIView.animate(withDuration: 1.5,
                delay: 0.5,
                usingSpringWithDamping: 0.2,
                initialSpringVelocity: 1,
                options: .curveEaseInOut,
                animations: {
  // 1
  self.redView.frame.size.width -= 50
  // 2
  self.redView.center.y += 200
  // 3
  self.redView.center.x = self.view.center.x
  // 4
  self.redView.alpha = 0.4
}, completion: { finished in
  // 5
  self.redView.backgroundColor = .systemBlue
})
```

Giải thích:
- Giống hệt với minh hoạ trên nhưng lần này method `animate` có thêm 2 property là `usingSpringWithDamping`, `initialSpringVelocity`.
- `usingSpringWithDamping`:
  - Làm cho animation dao động khi đến cuối animation. Có thể tưởng tượng nó như 1 cái `lò xo` làm cho animation bật nảy ở cuối animation.
  - Giá trị của nó giao động từ 0.0 -> 1.0. Giá trị càng nhỏ thì độ dao động càng lớn.
- `initialSpringVelocity`: là vận tốc ban đầu của `spring` (cái này test chả hiểu gì luôn :)) )

![](Images/Simulator-Screen-Recording-2.gif)
