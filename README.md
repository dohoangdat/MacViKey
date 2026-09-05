# MacViKey

Bộ gõ tiếng Việt: gọn - mượt - dành riêng cho MacOS

## Triết lý

Hầu hết bộ gõ tiếng Việt cho MacOS đều có hàng chục tuỳ chọn mà đa số người dùng không bao giờ đụng tới - và mỗi tuỳ chọn là một nhánh code có thể sinh lỗi.
MacViKey đi hướng ngược lại: tập trung vào kiểu gõ Telex, bảng mã Unicode, loại bỏ các tính năng thừa, và làm cho nó thật ổn định.

## Tính năng & Cơ chế hoạt động:

- Kiểu gõ Telex, bảng mã Unicode, dành riêng cho MacOS
- Hoạt động qua Accessibility API (thay vì giả lập phím Backspace) - mỗi lần thêm dấu là một thao tác nguyên tử, không đúp chữ, không mất chữ. Ứng dụng nào không hỗ trợ thì tự động lùi về đường giả lập phím.
- Xử lý lỗi gợi ý lặp tự động của trình duyệt (Chrome) hoặc Excel
- Tự khôi phục khi MacOS tắt event tap, giúp bộ gõ không còn "chết giữa chừng"
- Phím tắt chuyển nhanh Việt / Anh, chọn 1 trong 4 tổ hợp

MacViKey cố tình loại bỏ: các kiểu gõ cũ, các bảng mã cũ (khác Unicode), công cụ chuyển mã, gõ tắt, kiểm tra chính tả, bỏ dấu tự do, chuyển chế độ theo ứng dụng... Mỗi thứ đó là một nhánh code có thể
sinh lỗi, và rất ít người dùng tới.

## Cài đặt

### Cách 1 — Cài từ Homebrew

Mở **Terminal** (nhấn `⌘` + `Space`, gõ `Terminal`), dán lệnh:

```bash
brew install --cask dohoangdat/tap/macvikey
```

Nếu chưa có Homebrew? Cài Homebrew trước, dán lệnh:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- Cài xong, đóng Terminal và mở lại, rồi chạy lệnh cài MacViKey ở trên.
- Cập nhật `macvikey` sau này: `brew upgrade --cask macvikey`

### Cấp quyền Trợ năng

→ Cài đặt Hệ thống → Quyền riêng tư & Bảo mật → **Trợ năng** → bật **MacViKey**

Ứng dụng tự khởi động bộ gõ ngay khi quyền được cấp, không cần mở lại.

**Lưu ý**: hãy tắt các bộ gõ TV khác (gồm bộ gõ tiếng Việt có sẵn của
macOS) để tránh xung đột.


## Cấu trúc

```
Sources/MacViKey/
├── engine/          Engine tiếng Việt (C++ thuần, không phụ thuộc hệ điều hành)
├── macOS/
│   ├── MacViKey/        Ứng dụng: event tap, giao diện, đường Accessibility
│   └── MacViKeyHelper/  Login item để khởi động cùng hệ thống
└── tests/           Test hồi quy cho engine
```

Điểm đáng chú ý về kiến trúc: `engine/` là C++ thuần không đụng tới API macOS,
nên test được hoàn toàn ngoài Xcode. Lớp macOS chỉ làm nhiệm vụ chuyển kết quả
của engine thành thao tác trên màn hình.

## Giấy phép

```
[GNU General Public License v3.0](LICENSE)
Ứng dụng có sự tham khảo và phát triển thêm từ các OpenSource: OpenKey, EVkey, Unikey.
Copyright © 2026 Do Hoang Dat (MacViKey)
```

