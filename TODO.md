# Việc còn lại

Cập nhật lần cuối: 12/09/2026 — sau khi merge 10 commit vào `main`
(`f02a385..388c988`).

## Cân nhắc todo sau
- [ ] Menu bar, bỏ logo đi, chỉ cần VI/EN thôi
- [ ] Menu bar, chỉ drop down đơn giản, có nút mở giao diện GUI với các tùy chỉnh swiftui ở đó.

- [ ] **Gộp bảng nhanh và bảng điều khiển.** Sau khi bỏ hết tàn tích, hai cửa sổ
      chỉ còn khác nhau ở phần trạng thái bộ gõ và khôi phục mặc định. Ba cửa sổ
      cho một ứng dụng menu bar là nhiều.
- [ ] `MacViKeyHook.mm` còn 9 cảnh báo `unreachable-code`. Đó là hệ quả cố ý của
      `#define IS_DOUBLE_CODE(code) (0)` (khoá bảng mã Unicode dựng sẵn), nhưng
      cảnh báo thường trực làm lu mờ cảnh báo thật. Cân nhắc xoá hẳn các nhánh
      chết đó thay vì để compiler loại bỏ.
- [ ] Bộ gõ chưa có test nào ở lớp macOS — 48 test đều nằm ở engine C++. Đường
      Accessibility và cơ chế khôi phục event tap là chỗ dễ vỡ nhất mà không có
      lưới an toàn.

## Trước khi phát hành v1.1

- [ ] Bump `version.json` (`versionName`, `versionCode`) **trước** khi tạo
      release. Bộ gõ đọc file này trên nhánh `main` qua
      `raw.githubusercontent.com`, nên quên bump là người dùng không thấy bản mới.
- [ ] Tạo GitHub Release `v1.1` và upload `MacViKey-1.1.dmg`.
- [ ] Chạy `tools/release.sh`, lấy `version` + `sha256` từ output, cập nhật
      `tools/homebrew/macvikey.rb`. File này đang để `sha256` giả (toàn số 0).
- [ ] Copy cask sang repo `dohoangdat/homebrew-tap` tại `Casks/macvikey.rb`.
- [ ] Thử `brew install --cask dohoangdat/tap/macvikey` trên một máy sạch.

## Dọn dẹp

- [ ] Xoá branch đã merge:
      `git branch -d fix/dong-bo-cau-hinh && git push origin --delete fix/dong-bo-cau-hinh`
- [ ] Nâng `actions/checkout@v4` → `@v5` trong `.github/workflows/test.yml`.
      Node.js 20 đã deprecate, runner đang ép chạy trên Node 24.



## Ghi chú

Chữ ký hiện tại (chứng chỉ tự ký `MacViKey Self Signed`) neo Designated
Requirement vào chứng chỉ chứ không vào cdhash:

```
identifier "com.mac.vi.key" and certificate leaf = H"fea3c4da7413b61e4b5bf1a5c939e28fe7330178"
```

Nghĩa là quyền Trợ năng sống qua mọi lần build sau — không phải cấp lại nữa.
Đừng quay về ký ad-hoc (`CODE_SIGN_IDENTITY="-"`, tức `tools/build.sh`) cho bản
đưa người khác dùng, vì mỗi lần build sẽ là một app lạ với macOS.
