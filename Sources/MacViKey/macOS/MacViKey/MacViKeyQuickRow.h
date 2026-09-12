//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyQuickRow.h
//  MacViKey — mô tả một dòng của bảng nhanh, để lớp SwiftUI vẽ lại
//
//  Vì sao cần lớp mô tả này: MenuLayout.json là nguồn sự thật duy nhất cho cả
//  menu trên thanh trạng thái và bảng nhanh. Phía Objective-C đi cây JSON đó
//  (đã có sẵn bộ lọc cờ biên dịch + cờ "enabled"), rồi trả ra một danh sách
//  dòng phẳng; SwiftUI chỉ việc vẽ. Nếu để Swift tự đọc JSON thì thành hai bộ
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
  /// Tiêu đề nhóm; các dòng con nằm trong `children`.
  MacViKeyQuickRowKindGroup,
  /// Dòng trạng thái - nút lớn ở đầu bảng.
  MacViKeyQuickRowKindStatus,
  /// Thông tin đã khoá cứng (kiểu gõ, bảng mã): chỉ đọc.
  MacViKeyQuickRowKindFixedInfo,
  /// Tuỳ chọn bật/tắt; `tag` là MacViKeyOptionTag.
  MacViKeyQuickRowKindToggle,
  /// Chọn một trong nhiều; `tag` là chỉ số trong mnuSwitchKeyValues.
  MacViKeyQuickRowKindRadio,
  /// Nút chạy một hành động; nhận biết qua `rowId`.
  MacViKeyQuickRowKindAction,
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
/// Hành động mang tính phá huỷ (Thoát) - SwiftUI tô khác màu.
@property(nonatomic) BOOL destructive;
@property(nonatomic, copy) NSArray<MacViKeyQuickRow *> *children;

+ (instancetype)rowWithKind:(MacViKeyQuickRowKind)kind
                      rowId:(NSString *)rowId
                      title:(NSString *)title;

@end

/// Bảng nhanh gọi ngược về AppDelegate qua giao thức này. Không có tham chiếu
/// nào từ Swift sang AppDelegate, nên không sinh vòng phụ thuộc.
@protocol MacViKeyQuickPanelActions <NSObject>

/// Dựng lại danh sách dòng theo trạng thái hiện tại.
- (NSArray<MacViKeyQuickRow *> *)quickPanelRows;
/// Tiêu đề dòng trạng thái, luôn khớp với dòng đầu menu thanh trạng thái.
- (NSString *)quickPanelStatusTitle;
- (void)quickPanelDidToggleOptionWithTag:(NSInteger)tag;
- (void)quickPanelDidSelectSwitchKeyAtIndex:(NSInteger)index;
- (void)quickPanelDidTapStatusLine;
- (void)quickPanelDidTapActionWithId:(NSString *)rowId;

@end

/// Bang dieu khien goi nguoc ve AppDelegate qua giao thuc nay.
@protocol MacViKeyControlPanelActions <NSObject>

/// Cau trang thai bo go, dung chuoi ma menu thanh trang thai dang dung.
- (NSString *)controlPanelStatusTitle;
- (BOOL)controlPanelEngineIsRunning;
- (void)controlPanelRestartEngine;
- (void)controlPanelOpenQuickPanel;
- (void)controlPanelOpenAbout;
/// Dat lai moi tuy chon ve mac dinh xuat xuong.
- (void)controlPanelResetToDefaults;

@end

NS_ASSUME_NONNULL_END
