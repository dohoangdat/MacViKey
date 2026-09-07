# Công cụ chẩn đoán

## ax_spike

Kiểm tra một ứng dụng có cho phép thay thế văn bản qua Accessibility API hay
không — tức là có dùng được **chế độ thay thế thông minh** của MacViKey không.

```bash
clang -fobjc-arc -framework Cocoa -framework ApplicationServices -o ax_spike ax_spike.m
./ax_spike 5      # 5 giây để chuyển sang ứng dụng cần kiểm tra
```

Cần cấp quyền Trợ năng cho Terminal. Công cụ sẽ đặt con trỏ vào ô nhập của ứng
dụng đang focus, thử bôi đen 3 ký tự cuối và ghi đè, rồi báo kết quả từng bước.

Dùng để dựng bảng tương thích khi cần biết ứng dụng nào nên bật chế độ này.

## release.sh

Build bản Release, ký bằng chứng chỉ tự ký, đóng `.dmg` và in ra `sha256` để cập
nhật cask.

```bash
./tools/release.sh
```

### Tạo chứng chỉ tự ký (làm một lần duy nhất)

Ký ad-hoc (`CODE_SIGN_IDENTITY="-"`) khiến Designated Requirement rơi về `cdhash`,
đổi mỗi lần build — macOS coi là app lạ và **user phải cấp lại quyền Trợ năng sau
mỗi bản cập nhật**. Chứng chỉ tự ký cho DR ổn định, quyền Trợ năng giữ nguyên.

1. Mở **Keychain Access** → menu **Keychain Access** → **Certificate Assistant** →
   **Create a Certificate…**
2. Name: `MacViKey Self Signed`
3. Identity Type: **Self Signed Root**
4. Certificate Type: **Code Signing**
5. Create → Done

Đổi tên khác thì đặt biến môi trường `MVK_SIGN_IDENTITY`.

**Sao lưu ngay:** Keychain Access → tab *My Certificates* → chuột phải chứng chỉ →
**Export** ra `.p12`. Mất khoá này là mất DR — user sẽ phải cấp lại quyền Trợ năng.

### Sau khi build

`.dmg` chưa được Apple công chứng nên Gatekeeper vẫn chặn nếu user **tải thủ công**
(phải chuột phải → Open). Đường Homebrew không bị ảnh hưởng vì `brew` tự gỡ thuộc
tính `com.apple.quarantine`.

Cập nhật `version` và `sha256` trong `Casks/macvikey.rb` của repo
`homebrew-tap` — mẫu có sẵn tại [homebrew/macvikey.rb](homebrew/macvikey.rb).
