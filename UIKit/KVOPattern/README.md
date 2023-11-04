
## 1. 

KVO (Key-value Observing) là một Cocoa pattern cho phép một object được notify trực tiếp khi một property thuộc object khác thay đổi.

## 2.

Trong Swift chúng ta có 2 API giúp thực hiện KVO

Ví dụ:

``` swift
class Person: NSObject {
    @objc dynamic var age: Int
    @objc dynamic var name: String
}
```

### 2.1. API cũ

Swift được kế thừa KVO từ Objective-C, nhưng nó mặc định bị disable. Để có thể kích hoạt KVO thì class cần kế thừa NSObject:

```swift
class PersonObserver: NSObject {
    
    func observe(person: Person) {
        person.addObserver(self, forKeyPath: "age",
                           options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "age",
           let age = change?[.newKey] {
             print("New age is: \(age)")
        }
    }
}
```

### 2.2. API mới

```swift
class PersonObserver {

    var kvoToken: NSKeyValueObservation?
    
    func observe(person: Person) {
        kvoToken = person.observe(\.age, options: .new) { (person, change) in
            guard let age = change.new else { return }
            print("New age is: \(age)")
        }
    }
    
    deinit {
        kvoToken?.invalidate()
    }
}
```