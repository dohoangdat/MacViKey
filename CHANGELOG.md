# Lịch sử thay đổi

## 1.3 — chưa phát hành

<!-- Ghi thay doi vao day trong suot chu ky phat trien.
     Khi phat hanh: doi tieu de thanh "## 1.3 — dd/mm/yyyy" va bump
     version.json len 1.3 / versionCode 4. -->

## 1.2 — 13/09/2026

### Tính năng mới

- Cửa sổ Cài đặt viết lại bằng SwiftUI, có thanh bên: Tổng quan, Phím chuyển,
  Hệ thống, Giới thiệu, Ủng hộ, Liên kết
- Menu thả xuống chỉ còn VI/EN, Cài đặt và Thoát — mọi cấu hình chuyển hết vào
  cửa sổ Cài đặt
- Dòng cảnh báo trên menu khi bộ gõ gặp sự cố, bấm để cấp quyền hoặc khởi động lại
- Hiển thị phiên bản hiện tại và lịch sử cập nhật trong nhóm Bảo trì
- Khởi động cùng máy bằng LaunchAgent, chạy được từ macOS 11

### Sửa lỗi

- Mất quyền Trợ năng giữa chừng không còn làm treo cả máy
- Cửa sổ Cài đặt luôn nổi lên trên
- Chỉ xử lý những phím có vai trò trong gõ tiếng Việt, các phím còn lại đi thẳng
  qua bộ gõ

### Thay đổi

- VI/EN đổi màu theo giao diện sáng/tối, icon menu 18px
- Bỏ tự động kiểm tra bản mới lúc khởi động — chỉ kiểm tra khi người dùng bấm

### Hạ tầng

- Script đóng gói `.dmg` ký bằng chứng chỉ tự ký, giữ quyền Trợ năng qua mọi
  lần cập nhật
- Cask Homebrew
- GitHub Actions chạy test hồi quy và build thử

## 1.0.0 — chưa phát hành

### Sửa lỗi

- Bộ gõ không còn tự chết. macOS tắt event tap khi callback chạy chậm và gửi
  `kCGEventTapDisabledByTimeout`; bản gốc bỏ qua sự kiện này nên tap chết vĩnh
  viễn cho tới khi khởi động lại ứng dụng
- Thêm watchdog 5 giây, bắt trường hợp tap chết âm thầm sau khi máy thức dậy
- Ứng dụng không còn tự thoát khi chưa có quyền Trợ năng. Bản gốc hiện `NSAlert`
  rồi `terminate` ngay, nhưng alert không render được với ứng dụng `LSUIElement`
  chưa activate — kết quả là app thoát im lặng sau vài giây
- Giảm chi phí mỗi phím: bỏ 2 lần quét toàn bộ cửa sổ màn hình cho mỗi ký tự có
  bỏ dấu

### Tính năng mới

- Tắt bộ gõ riêng cho từng ứng dụng
- Chế độ thay thế thông minh dùng Accessibility API (mặc định tắt)
- Mục menu hiển thị trạng thái bộ gõ, bấm để khởi động lại
- Cửa sổ Cài đặt (SwiftUI) có thanh bên: Tổng quan, Phím chuyển, Hệ thống,
  Giới thiệu. Mọi cấu hình nằm ở đây
- Bảng nhanh: bấm vào MacViKey.app mở một cửa sổ có đúng nội dung của menu
- Ẩn biểu tượng khỏi thanh menu (vẫn vào lại được qua bảng nhanh)
- Khởi động cùng máy hoạt động từ macOS 11 (LaunchAgent), không cần helper

### Thay đổi

- Chỉ còn kiểu gõ Simple Telex 1 và bảng mã Unicode dựng sẵn
- Bỏ công cụ chuyển mã
- Bỏ các tuỳ chọn chính tả và gõ tắt phụ âm
- Bỏ mã nguồn Windows và Linux
- Bundle identifier giữ nguyên `com.mac.vi.key`
- Yêu cầu tối thiểu macOS 11 (Big Sur) — giao diện dùng SwiftUI
- Toàn bộ giao diện cửa sổ viết lại bằng SwiftUI; bỏ `AboutViewController`,
  `ViewController`, `MyTextField` và 707 dòng storyboard
- Cả ứng dụng giờ chỉ còn MỘT cửa sổ: Cài đặt. Bảng nhanh, bảng điều khiển và
  cửa sổ Giới thiệu gộp vào đó
- Biểu tượng trên thanh menu chỉ còn chữ VI / EN, bỏ logo
- Menu thả xuống chỉ còn trạng thái, thông tin phím chuyển, nút mở Cài đặt và
  Thoát
- Hiện biểu tượng trên thanh Dock đổi thành mặc định BẬT

### Hạ tầng

- 48 test hồi quy cho engine, chạy độc lập không cần Xcode
- GitHub Actions chạy test hồi quy engine và build thử ứng dụng mỗi commit
