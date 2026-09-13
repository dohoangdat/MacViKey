# Ý tưởng tiện ích mở rộng cho MacViKey

Cập nhật: 13/09/2026

Ba (bốn) nhóm tiện ích cân nhắc thêm vào MacViKey: **Clipboard Utils**,
**Dev Utils**, **Mac Utils**, và **Student Utils**.

Nguyên tắc lọc:

- **Offline hoàn toàn.** Không tính năng nào gọi server.
- **Không thêm dependency.** Chỉ dùng framework có sẵn của macOS
  (Foundation, AppKit, Vision, PDFKit, ImageIO, CryptoKit, IOKit, CoreAudio…).
- **Logic đơn giản.** Phần lớn là hàm thuần vài chục dòng.

Ba thứ MacViKey đã có sẵn khiến việc này thuận lợi: app menu bar chạy nền
thường trực, quyền Accessibility đã được cấp, và event tap bắt phím toàn hệ
thống. Cả bốn nhóm đều dùng lại đúng ba thứ đó.

Ký hiệu: **VP** = dân văn phòng · **DEV** = lập trình viên · **SV** = sinh viên.

---

## Tier 1 — Dùng hàng ngày, làm trước

| # | Tính năng | Ai | API dùng |
|---|---|---|---|
| 1 | **Lịch sử clipboard** + bảng nổi gọi bằng hotkey, gõ để lọc, Enter để dán | VP DEV SV | `NSPasteboard.changeCount` |
| 2 | **Dán thành plain text** (bỏ font, màu, cỡ chữ khi copy từ web/Word) | VP SV | `NSPasteboard` |
| 3 | **Trim**: bỏ khoảng trắng thừa, dòng trống, zero-width, non-breaking space | VP DEV | `String` |
| 4 | **JSON format / minify / validate**, báo lỗi ở vị trí nào | DEV | `JSONSerialization` |
| 5 | **Tắt màn hình ngay** mà máy vẫn chạy ngầm (build, tải, họp không tắt) | VP DEV | `IOPMAssertion` |
| 6 | **Caffeine** — chặn ngủ, hẹn 30p/1h/vô hạn, icon đổi trạng thái | VP DEV SV | `IOPMAssertion` |
| 7 | **Đổi kiểu chữ**: UPPER, lower, Title Case, camelCase, snake_case, kebab-case | VP DEV | `String` |
| 8 | **Bỏ dấu tiếng Việt** + tạo slug URL — đúng sở trường sẵn có của app | VP DEV SV | engine C++ đã có |
| 9 | **Sinh mật khẩu**: độ dài, ký tự đặc biệt, kiểu dễ đọc (bỏ `l1IO0`), passphrase | VP DEV | `SecRandomCopyBytes` |
| 10 | **Chụp vùng chọn → clipboard**, kèm **OCR lấy chữ** (đọc được tiếng Việt) | VP DEV SV | `Vision` |
| 11 | **Base64 / URL encode-decode** hai chiều | DEV | `Data` |
| 12 | **Timestamp ↔ ngày giờ**, hai chiều, theo giờ máy và UTC | DEV | `Date` |
| 13 | **Đếm ký tự / từ / dòng** của clipboard hoặc text bôi đen | VP SV | `String` |
| 14 | **Ghim (pin)** mục clipboard hay dùng — mã nhân viên, số tài khoản, template mail | VP | như #1 |

## Tier 2 — Dùng hàng tuần

| # | Tính năng | Ai |
|---|---|---|
| 15 | **Sinh UUID** v4/v7, ULID, chuỗi hex/base62 ngẫu nhiên | DEV |
| 16 | **Hash** MD5 / SHA-1 / SHA-256 của clipboard hoặc file kéo thả vào | DEV |
| 17 | **JWT decode** — header + payload, cảnh báo hết hạn (giải mã cục bộ, không verify chữ ký) | DEV |
| 18 | **Sắp xếp dòng, bỏ dòng trùng** | VP DEV |
| 19 | **Nối dòng thành một dòng** / tách theo dấu phẩy thành nhiều dòng | VP DEV |
| 20 | **Bộ ba Finder**: ẩn/hiện file ẩn, copy đường dẫn file đang chọn, mở Terminal tại thư mục đang mở | VP DEV |
| 21 | **Color picker** lấy màu từ màn hình + chuyển HEX ↔ RGB ↔ HSL | DEV |
| 22 | **Sinh QR từ clipboard** (chia sẻ wifi, link, số điện thoại sang điện thoại) | VP DEV SV |
| 23 | **Đọc QR/barcode từ ảnh** trong clipboard | VP |
| 24 | **Chuyển nguồn âm thanh** tai nghe ↔ loa ↔ micro, không vào System Settings | VP DEV SV |
| 25 | **Giữ cửa sổ luôn trên cùng** (always on top) cho app bất kỳ | VP DEV SV |
| 26 | **Restart Finder / Dock / SystemUIServer** khi giao diện đơ | DEV |
| 27 | **Port đang bận** — liệt kê gọn, kill nhanh tiến trình chiếm port | DEV |
| 28 | **Regex tester** — pattern + text mẫu, highlight match, hiện capture group | DEV |
| 29 | **Diff 2 mục clipboard gần nhất**, highlight dòng khác nhau | DEV |
| 30 | **Xoá `.DS_Store`** đệ quy trong một thư mục | DEV |
| 31 | **Số ↔ chữ tiếng Việt** ("1.250.000" → "một triệu hai trăm năm mươi nghìn") | VP |
| 32 | **Máy tính nhanh trong ô tìm kiếm** — gõ `1250*1.1` ra kết quả, copy luôn | VP SV |

## Tier 3 — Dùng thỉnh thoảng, nhưng "cứu" lúc cần

| # | Tính năng | Ai |
|---|---|---|
| 33 | **Đổi độ phân giải / scale màn hình** nhanh khi trình chiếu | VP DEV |
| 34 | **Eject toàn bộ ổ ngoài** một lần | VP |
| 35 | **Xem nhanh pin, RAM, dung lượng đĩa** trong menu | VP DEV SV |
| 36 | **Ẩn tất cả cửa sổ / chế độ tập trung** một phím | VP |
| 37 | **HTML entities** encode-decode | DEV |
| 38 | **Escape/unescape** chuỗi cho JSON, SQL, shell | DEV |
| 39 | **CIDR calculator** — `192.168.1.0/24` ra dải IP, netmask, số host | DEV |
| 40 | **Xem IP nội mạng** các interface (`en0`, `en1`, VPN) — đọc cục bộ | DEV |
| 41 | **Hex ↔ Dec ↔ Bin ↔ Oct** | DEV |
| 42 | **Chuyển đổi đơn vị dung lượng** KB/MB/GB/TB | DEV |
| 43 | **Cron expression giải thích** — `0 3 * * 1` → "3h sáng thứ Hai hàng tuần" | DEV |
| 44 | **Đổi dấu phân cách số** 1,250.00 ↔ 1.250,00 (Excel Việt ↔ Anh) | VP |
| 45 | **Tách email / số điện thoại / URL** ra khỏi một đoạn text lộn xộn | VP |
| 46 | **CSV ↔ bảng** xem nhanh, đổi dấu phân cách `,` ↔ `;` ↔ Tab | VP |
| 47 | **Lorem ipsum / text mẫu tiếng Việt** để test giao diện | DEV |
| 48 | **Đổi tên file hàng loạt** theo mẫu trong thư mục đang chọn | VP |
| 49 | **Nén ảnh / resize ảnh** kéo thả | VP |
| 50 | **Chuyển HEIC → JPG/PNG** kéo thả | VP |
| 51 | **Gộp / tách PDF, xoay trang** | VP |
| 52 | **Xoá metadata EXIF** khỏi ảnh trước khi gửi | VP |
| 53 | **Bàn phím emoji / ký tự đặc biệt** có tìm kiếm tiếng Việt | VP |
| 54 | **Unicode inspector** — xem từng ký tự, code point, phát hiện ký tự lạ trộn vào | DEV |
| 55 | **Đồng hồ đếm ngược / Pomodoro** trên menu bar | VP SV |
| 56 | **Ghi chú nháp** một ô text luôn sẵn trong menu, tự lưu | VP SV |
| 57 | **Xem clipboard dạng hex** cho lúc debug ký tự lạ | DEV |
| 58 | **Chuyển đổi múi giờ** cho lịch họp (tzdata có sẵn trong macOS) | VP |
| 59 | **Tính ngày** — cộng/trừ ngày, đếm ngày giữa hai mốc, số ngày làm việc | VP |
| 60 | **Xoá an toàn** — ghi đè rồi xoá file nhạy cảm | DEV |

---

## Student Utils — nhóm sinh viên dùng Mac

Sinh viên dùng lại gần hết Tier 1 (lịch sử clipboard, OCR, Caffeine, đếm từ,
bỏ dấu để đặt tên file bài nộp). Phần dưới là những thứ chỉ sinh viên cần.

### Học và làm bài

| # | Tính năng | Ghi chú |
|---|---|---|
| 61 | **Ký tự toán học & Hy Lạp** — α β γ ∑ ∫ √ ≤ ≥ ≈ ∞ ⇒ ∂ ∇, chèn bằng hotkey, có tìm kiếm tiếng Việt ("tổng" → ∑) | Sinh viên kỹ thuật gõ liên tục mà bảng emoji của macOS không có. Chỉ là một bảng tra tĩnh. |
| 62 | **LaTeX → Unicode** — gõ `\alpha` `\sum` `\leq` ra α ∑ ≤ ngay trong Word, Google Docs, Notion | Bảng ánh xạ tĩnh ~200 mục, không cần thư viện LaTeX nào. |
| 63 | **Đọc to văn bản (TTS)** — nghe lại bài luận để soát câu lủng củng, hoặc luyện nghe ngoại ngữ | `AVSpeechSynthesizer`, giọng offline có sẵn, hỗ trợ tiếng Việt. |
| 64 | **Flashcard nhanh từ clipboard** — copy một cặp "từ – nghĩa", lưu thành thẻ, ôn theo spaced repetition | Thuật toán SM-2 khoảng 30 dòng, không cần thư viện. |
| 65 | **Tính GPA / điểm trung bình có trọng số** — nhập điểm + số tín chỉ, ra GPA hệ 4 và hệ 10 | Mỗi trường một thang quy đổi, nên cho tự cấu hình bảng quy đổi. |
| 66 | **Đếm ngược deadline** — danh sách deadline trên menu bar, hiện cái gần nhất | Rất hợp menu bar: nhìn thấy mà không phải mở app. |
| 67 | **Ảnh chụp bảng → PDF nhiều trang** — chọn loạt ảnh, gộp thành một PDF nộp bài | `PDFKit`. |
| 68 | **OCR loạt ảnh slide → text** — chụp slide giảng đường rồi rút chữ ra để ghi chú | Mở rộng của #10, chạy hàng loạt. |
| 69 | **Bảng tuần hoàn tra cứu** — ký hiệu, số hiệu, khối lượng nguyên tử | Một file JSON 118 dòng nhúng sẵn. |
| 70 | **Chuyển đổi đơn vị vật lý/hoá học** — độ dài, khối lượng, nhiệt độ, áp suất, năng lượng, mol | Toán học thuần. |
| 71 | **Máy tính khoa học** — lượng giác, log, luỹ thừa, dấu ngoặc, lịch sử phép tính | Mở rộng của #32. |
| 72 | **Số La Mã ↔ số thường** | Lịch sử, luật, đánh số chương mục. |

### Tập trung và giữ sức

| # | Tính năng | Ghi chú |
|---|---|---|
| 73 | **Pomodoro có thống kê** — 25/5, đếm số phiên đã học hôm nay | Mở rộng của #55. |
| 74 | **Nhắc nghỉ mắt 20-20-20** — mỗi 20 phút nhắc nhìn xa 20 giây | Ngồi Mac 8 tiếng liền là chuyện thường của sinh viên. |
| 75 | **Tạm ẩn/thoát app gây xao nhãng** — chọn danh sách app, một phím ẩn hết trong giờ học | Chỉ ẩn/quit app cục bộ, không đụng tới mạng hay DNS. |
| 76 | **Chia màn hình 2 cửa sổ** — tài liệu bên trái, ghi chép bên phải, một hotkey | Thao tác học tập phổ biến nhất trên màn hình 13". |
| 77 | **Hẹn giờ tắt máy / ngủ** — đặt nhạc học bài rồi ngủ quên | `pmset` cục bộ. |
| 78 | **Zoom / highlight con trỏ** khi thuyết trình nhóm hoặc quay màn hình | `CoreGraphics`. |
| 79 | **Ghi âm nhanh** — một phím bắt đầu ghi bài giảng, lưu vào thư mục cố định | `AVAudioRecorder`. Không OCR, không nhận dạng giọng nói — chỉ ghi. |
| 80 | **Night Shift / True Tone / chế độ tối** bật tắt nhanh khi học đêm | |

### Việc nhóm và nộp bài

| # | Tính năng | Ghi chú |
|---|---|---|
| 81 | **Đổi tên file theo chuẩn nộp bài** — mẫu `MSSV_HoTen_BaiTap`, áp cho cả thư mục | Mở rộng của #48 với template lưu sẵn. |
| 82 | **Nén thư mục thành zip** một cú nhấp, đặt tên theo template | |
| 83 | **Chọn ngẫu nhiên / chia nhóm** — bốc tên thuyết trình, chia lớp thành N nhóm | |
| 84 | **Chia hoá đơn nhóm** — tổng tiền chia N, làm tròn nghìn | Vui nhưng dùng thật. |
| 85 | **Sinh trích dẫn APA / MLA / IEEE từ form nhập tay** — điền tác giả, năm, tiêu đề, ra đúng định dạng | Chỉ là template chuỗi. Không tra cứu DOI/ISBN vì thứ đó cần mạng. |
| 86 | **Kiểm tra bài luận cơ bản** — câu quá dài, lặp từ, dòng trống thừa, hai dấu cách liền nhau | Toàn bộ là luật chuỗi, không phải AI. |

---

## Đã loại vì cần mạng

IP công cộng · tra cứu ASN/quốc gia · WHOIS · DNS lookup · kiểm tra SSL/domain ·
rút gọn link · dịch văn bản · từ điển · kiểm tra chính tả online · đồng bộ
clipboard giữa các máy · tra mã bưu chính · tỷ giá tiền tệ · thời tiết ·
tra cứu trích dẫn theo DOI/ISBN · kiểm tra đạo văn.

**Tỷ giá** và **đồng bộ clipboard** là hai thứ người dùng sẽ hỏi nhiều nhất.
Nếu sau này làm, nên tách thành mục riêng có công tắc rõ ràng, vì chúng phá vỡ
tính chất "app hoàn toàn offline" mà MacViKey đang có — đó là một điểm bán hàng
thật, nhất là với một bộ gõ bàn phím, nơi người dùng vốn đã lo chuyện app đọc
trộm phím.

---

## Những điều cần quyết trước khi code

1. **Định vị sản phẩm.** Bốn nhóm này biến MacViKey từ "bộ gõ tiếng Việt" thành
   "bộ tiện ích có kèm bộ gõ". Đó là thay đổi về định vị, không chỉ là thêm
   tính năng.

2. **Mặc định tắt hết.** Người chỉ cần gõ tiếng Việt không nên phải trả giá bằng
   RAM và một vòng poll clipboard chạy suốt. Bật từng nhóm trong Cài đặt.

3. **Lịch sử clipboard là dữ liệu nhạy cảm.** Chốt trước: lưu ở đâu, có mã hoá
   không, có xoá khi thoát app không, và bỏ qua nội dung có
   `org.nspasteboard.ConcealedType` (1Password, Keychain) như thế nào.

4. **`TODO.md` đang ghi "ba cửa sổ cho một app menu bar là nhiều"** và muốn gộp
   bớt. Thêm bốn nhóm tiện ích sẽ đi ngược hướng đó, trừ khi làm chung trong một
   cửa sổ có sidebar. Nên gộp cửa sổ trước, rồi mới thêm tiện ích vào khung đã gọn.

5. **Mục 49–52 và 67, 82 là xử lý file, không phải xử lý text.** Chúng phổ biến
   thật, nhưng kéo app sang một thể loại khác và cần giao diện kéo-thả riêng.
   Cân nhắc gom thành nhóm "File Utils" thứ năm, hoặc để dành hẳn.

6. **Ước lượng thô.** Tier 1 là phần việc lớn nhất vì lịch sử clipboard cần lưu
   trữ, bảng nổi và hotkey toàn cục — ba thứ đó chiếm quá nửa công sức. Từ Tier 2
   trở đi phần lớn là hàm thuần, thêm rất nhanh một khi khung giao diện đã dựng.

## Đề xuất phạm vi v1

Sáu món, phủ đủ bốn nhóm người dùng, và dựng xong hạ tầng dùng chung
(hotkey toàn cục + bảng nổi + khung cài đặt) cho mọi thứ về sau:

- #1 Lịch sử clipboard
- #3 Trim
- #4 JSON format
- #5 Tắt màn hình ngay
- #10 Chụp vùng chọn + OCR
- #61 Bảng ký tự toán học
- #61 Bảng ký tự UTF8
