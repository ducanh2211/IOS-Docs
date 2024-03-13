
Cookie vs Token Authentication

Cùng tìm hiểu về cách hệ thống authentication hoạt động.

![](images/cookie-token-auth.png)

### Cookie-based Authentication

`Cookie-based Authentication` đã sử dụng rộng rãi và coi là mặc định trong 1 thời gian rất lâu.

`Cookie-based Authentication` là **stateful**. Tức là 1 authentication record hoặc 1 authentication session phải được giữ lại giữa cả 2 phía client - server. Bên phía server sẽ phải theo dõi *active session* trong database, trong khi đó client sẽ giữ lại 1 `cookie` được trả từ server mà giúp lưu trữ *1 session identifier*.

Flow của `Cookie-based Authentication` truyền thống:
1. User đăng nhập vào web, app (gửi credentials)...
2. Server check lại thông tin đăng nhập (credentials), nếu thông tin chuẩn nó sẽ tạo ra 1 session và lưu vào database.
3. 1 cookie có chứa *session ID* được lưu trong users browser.
4. Khi gửi các request phụ, *session ID* sẽ được check với database, nếu nó hợp pháp thì request sẽ được thực hiện.
5. Khi mà user log out, session bị huỷ bỏ ở cả 2 phía client - server.

### Token-based Authentication

Khi nhắc đến authentication với token, nhìn chung sẽ là authentication với `JSON Web Tokens (JWTs)`. Mặc dù có nhiều cách để implement tokens, JWTs đã trở thành 1 chuẩn mực chung.

`Token-based Authentication` là **stateless**. Tức là server sẽ không giữ lại record của user đã đăng nhập hoặc JWTs đã được khởi tạo. Thay vào đó, mỗi request sẽ đính kèm `token` để giúp server kiểm tra authentication. 

`Token` thường được gửi trong header's request dưới dạng `Bearer {JWT}`, hoặc có thể gửi trong body của *POST request* , hoặc trong query parameter.

Flow của `Token-based Authentication`:
1. User đăng nhập vào web, app (gửi credentials)...
2. Server check lại thông tin đăng nhập (credentials), nếu thông tin chuẩn nó sẽ trả lại 1 `token` xác thực.
3. `Token` này được lưu ở client, thường là ở `local storage`, hoặc `session storage`.
4. Khi gửi các request phụ, `token` được đính trong `Authorizaation header`.
5. Server sẽ decode JWT và nếu token hợp lệ request sẽ được thực thi.
6. Khi mà user log out, client sẽ huỷ bỏ 

### Lợi điểm của Token-based Authentication

Những đặc điểm giúp cho JWTs được ưu tiên so với Cookies truyền thống

#### Stateless, Scalable, and Decoupled

- Lợi ích lớn nhất của JWTs là stateless.
- Nó giúp cho server không phải lưu trữ bất kỳ dữ liệu gì.
- Mỗi 1 token là self-contained, nó chứa toàn bộ data cần thiết để check tính validity và user info.
- Server chỉ cần check tính validity của token, và token được issue bởi third-party như AuthO.

#### Cross Domain and CORS (cái này loằng ngoằng quá deo hiểu, để sau đi :D)

#### Lưu data trong JWT

Ngược lại với cookie chỉ lưu mỗi `sessionID`, JWTs có thể lưu bất kề metadata nào miễn nó tuân thủ JSON format (ở dưới có giải thích về cấu trúc của 1 token).

Tuy nhiên việc lưu data nhạy cảm trong token là không nên vì bản chất thì token không được mã hoá.

#### Phù hợp với mobile application

Thường thì mobile app sẽ không phù hợp với cookies, nhưng token thì lại khác. Nếu API được sử dụng với nhiều platform như web, mobile thì việc sử dụng token bên phía server sẽ là hợp lý.

### Cấu trúc của JWTs

JWTs bao gồm 3 phần, được ngăn cách bởi dấu (.): `Header`, `Payload`, `Signature`.

Format của JWTs: `xxxxx.yyyyy.zzzzz`.

Ví dụ: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY2hvb2wiOiJIVVNUIiwibmFtZSI6IkxlIFZpZXQgSG9hbmciLCJhZG1pbiI6dHJ1ZX0.QM7C7vuOyklOegqP2TrhH1wAvHJLSjF-UFfNItqJkQA`

![](images/6de93ad9-2638-4bd3-9670-5231abec3b0d.png)


# REFERENCE:
1. [cookies-vs-tokens-the-definitive-guide](https://dzone.com/articles/cookies-vs-tokens-the-definitive-guide)
2. [json-web-token-hay-session-cookies-dau-moi-la-chan-ai](https://viblo.asia/p/json-web-token-hay-session-cookies-dau-moi-la-chan-ai-Qbq5Q0oJlD8)