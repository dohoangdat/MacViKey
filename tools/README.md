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
