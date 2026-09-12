//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyQuickRow.h
//  MacViKey — mô tả các trang và dòng của cửa sổ Cài đặt, để SwiftUI vẽ lại
//
//  Vì sao cần lớp mô tả này: MenuLayout.json là nguồn sự thật duy nhất cho cả
//  menu trên thanh trạng thái và cửa sổ Cài đặt. Phía Objective-C đi cây JSON
//  đó (đã có sẵn bộ lọc cờ biên dịch + cờ "enabled"), rồi trả ra danh sách
//  trang/dòng; SwiftUI chỉ việc vẽ. Nếu để Swift tự đọc JSON thì thành hai bộ
//  luật lọc song song, và đó đúng là kiểu lệch mà dự án đang cố tránh.
//
//  Copyright © 2026 Do Hoang Dat
//
//  This file is part of MacViKey.
//
//  MacViKey is free software: you can redistribute it and/or modify it under
//  the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option)
//  any later version.
//
//  MacViKey is distributed in the hope that it will be useful, but WITHOUT ANY
//  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
//  FOR A PARTICULAR PURPOSE. See the GNU General Public License for details.
//
//  You should have received a copy of the GNU General Public License along
//  with MacViKey. If not, see <https://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MacViKeyQuickRowKind) {
  /// Đường kẻ ngang.
  MacViKeyQuickRowKindSeparator = 0,
  /// Một trang trong thanh bên của cửa sổ Cài đặt; các dòng nằm trong `children`.
  MacViKeyQuickRowKindPage,
  /// Dòng chế độ gõ Việt / Anh.
  MacViKeyQuickRowKindStatus,
  /// Thông tin đã khoá cứng (kiểu gõ, bảng mã): chỉ đọc.
  MacViKeyQuickRowKindFixedInfo,
  /// Dòng chỉ đọc dạng "nhãn — giá trị" (ví dụ: phiên bản hiện tại).
  MacViKeyQuickRowKindInfoValue,
  /// Tuỳ chọn bật/tắt; `tag` là MacViKeyOptionTag.
  MacViKeyQuickRowKindToggle,
  /// Chọn một trong nhiều; `tag` là chỉ số trong mnuSwitchKeyValues.
  MacViKeyQuickRowKindRadio,
  /// Nút chạy một hành động; nhận biết qua `rowId`.
  MacViKeyQuickRowKindAction,
  /// Trang thông tin (Giới thiệu, Ủng hộ, Liên kết) - SwiftUI tự vẽ theo
  /// `rowId`, không sinh từ `children`.
  MacViKeyQuickRowKindInfoPage,
};

@interface MacViKeyQuickRow : NSObject

@property(nonatomic) MacViKeyQuickRowKind kind;
/// Trùng với "id" trong MenuLayout.json.
@property(nonatomic, copy) NSString *rowId;
@property(nonatomic, copy) NSString *title;
/// Câu hướng dẫn ("hint" trong JSON), hiện khi rê chuột.
@property(nonatomic, copy, nullable) NSString *hint;
@property(nonatomic) NSInteger tag;
@property(nonatomic) BOOL on;
/// Hành động mang tính phá huỷ (khôi phục mặc định) - SwiftUI tô khác màu và
/// hỏi lại trước khi chạy.
@property(nonatomic) BOOL destructive;
/// Tên SF Symbol cho biểu tượng trang trong thanh bên ("symbol" trong JSON).
@property(nonatomic, copy, nullable) NSString *symbol;
/// Giá trị hiện bên phải của dòng chỉ đọc (kind = InfoValue).
@property(nonatomic, copy, nullable) NSString *value;
/// Chữ trên nút của dòng hành động ("button" trong JSON).
@property(nonatomic, copy, nullable) NSString *buttonTitle;
@property(nonatomic, copy) NSArray<MacViKeyQuickRow *> *children;

+ (instancetype)rowWithKind:(MacViKeyQuickRowKind)kind
                      rowId:(NSString *)rowId
                      title:(NSString *)title;

@end

/// Cửa sổ Cài đặt gọi ngược về AppDelegate qua giao thức này. Không có tham
/// chiếu nào từ Swift sang AppDelegate, nên không sinh vòng phụ thuộc.
@protocol MacViKeySettingsActions <NSObject>

/// Dựng lại danh sách trang + dòng theo trạng thái hiện tại.
- (NSArray<MacViKeyQuickRow *> *)settingsPages;
/// Câu trạng thái bộ gõ, dùng đúng chuỗi mà menu thanh trạng thái đang dùng.
- (NSString *)settingsStatusTitle;
/// YES nếu đang gõ Tiếng Việt.
- (BOOL)settingsVietnameseIsOn;
- (BOOL)settingsEngineIsRunning;
- (void)settingsSetVietnamese:(BOOL)on;
- (void)settingsRestartEngine;
- (void)settingsToggleOptionWithTag:(NSInteger)tag;
- (void)settingsSelectSwitchKeyAtIndex:(NSInteger)index;
- (void)settingsRunActionWithId:(NSString *)rowId;

@end

NS_ASSUME_NONNULL_END
