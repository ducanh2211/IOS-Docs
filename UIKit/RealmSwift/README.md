
# 1. Model Data

## Declare properties

Khi khai báo property trong 1 class chúng ta có thể xét chúng là `Managed properties` hoặc `Ignored properties`. 

`Managed properties` sẽ được realm store và update trong database. Còn `Ignored properties` sẽ không được store và quản lý trong database. Có thể mix 2 loại properties này.

### Persisted Property Attributes vs Objective-C Dynamic Property Attributes

- Sau version 10.10.0:
    - Sử dụng property wrapper `@Persisted` để khai báo `Managed properties`.
    - Những properties không có `@Persisted` sẽ được coi là `Ignored properties`
- Trước version 10.10.0: 
    - Sử dụng `@objc dynamic var` để khai báo `Managed properties` hoặc sử dụng `@objcMembers` khai báo class và `dynamic var` để khai báo properties.
    - Sử dụng `let` để khai báo `LinkingObjects`, `List`, `RealmProperty`.
- Nếu như trong 1 class khai báo properties mix giữa `@Persisted` và `@objc dynamic var` thì toàn bộ properties được đánh dấu là `@objc dynamic var` sẽ bị coi là `Ignored properties`.

```swift
class Person: Object {
    // after version 10.10.0
    @Persisted var name = ""

    // before version 10.10.0
    @objc dynamic var name = ""
}
```

### Specify an Optional / Required Property

- After version 10.10.0

```swift
class Person: Object {
    // Required string property
    @Persisted var name = ""

    // Optional string property
    @Persisted var address: String?

    // Required numeric property
    @Persisted var ageYears = 0

    // Optional numeric property
    @Persisted var heightCm: Float?
}
```

- Before version 10.10.0

```swift
class Person: Object {
    // Required string property
    @objc dynamic var name = ""

    // Optional string property
    @objc dynamic var address: String?

    // Required numeric property
    @objc dynamic var ageYears = 0

    // Optional numeric property
    let heightCm = RealmProperty<Float?>()
}
```

Đọc thêm về *Supported Types* để biết thêm chi tiết: [Realm Swift docs](https://www.mongodb.com/docs/realm/sdk/swift/model-data/supported-types/#collections-are-live)

### Specify a Primary Key

Bạn có thể xét 1 property là `primary key`.

`Primary key` giúp chúng ta find, update và upsert objects hiệu quả hơn.

`Primary key` bị giới hạn:
-	Mỗi object sẽ có 1 primary key duy nhất để phân biệt với các object khác trong database.
-	Có thể chỉ định 1 property là primary key (không bắt buộc phải có).
-	Dùng để nâng cao hiệu quả khi query data và trong CRUD.
-	Primary key không thể bị chỉnh sửa, chỉ có thể xoá object đó đi và tạo mới.
-	`Embed object` không thể có primary key.

```swift
// After version 10.10.0
class Project: Object {
    @Persisted(primaryKey: true) var id = 0
    @Persisted var name = ""
}

// Before version 10.10.0 
class Project: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = ""

    // Return the name of the primary key property
    override static func primaryKey() -> String? {
        return "id"
    }
}
```

