# Lịch sử thay đổi

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

### Thay đổi

- Chỉ còn kiểu gõ Simple Telex 1 và bảng mã Unicode dựng sẵn
- Bỏ công cụ chuyển mã
- Bỏ các tuỳ chọn chính tả và gõ tắt phụ âm
- Bỏ mã nguồn Windows và Linux
- Bundle identifier giữ nguyên `com.mac.vi.key`
- Yêu cầu tối thiểu macOS 10.13

### Hạ tầng

- 48 test hồi quy cho engine, chạy độc lập không cần Xcode
- GitHub Actions chạy test mỗi commit
