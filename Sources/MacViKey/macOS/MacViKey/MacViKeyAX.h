//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyAX.h
//  MacViKey - đường thay thế văn bản qua Accessibility API
//
//  Thay vì bắn N lần Backspace rồi gõ lại (bất đồng bộ, dễ race), đường này
//  bôi đen N ký tự cuối và ghi đè bằng một lời gọi AX duy nhất - nguyên tử.
//
//  KHÔNG phải app nào cũng hỗ trợ. Module tự dò khả năng theo bundle ID,
//  cache lại, và trả về NO để lớp gọi rơi về đường CGEventTap cũ.
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

#ifndef MacViKeyAX_h
#define MacViKeyAX_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Bật/tắt toàn bộ đường AX (đọc từ NSUserDefaults "vUseAccessibilityPath").
BOOL MacViKeyAXIsEnabled(void);
void MacViKeyAXSetEnabled(BOOL on);

/// Gọi khi đổi app: xoá cache con trỏ và dò lại khả năng của app mới.
void MacViKeyAXOnAppChanged(NSString* bundleId);

/// Thay thế `backspaceCount` ký tự ngay trước con tr��� bằng `newText`.
/// Trả về YES nếu thành công (lớp gọi KHÔNG cần giả lập phím nữa).
BOOL MacViKeyAXReplaceText(int backspaceCount, NSString* newText);

#ifdef __cplusplus
}
#endif

#endif /* MacViKeyAX_h */
